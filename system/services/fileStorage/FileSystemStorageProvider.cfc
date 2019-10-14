/**
 * Implementation of the [[api-storageprovider]] interface to provide a file system based
 * storage provider.
 *
 * @singleton
 * @autodoc
 *
 */
component implements="preside.system.services.fileStorage.StorageProvider" displayname="File System Storage Provider" {

// CONSTRUCTOR
	public any function init(
		  required string rootDirectory
		, required string trashDirectory
		, required string privateDirectory
		,          string rootUrl=""
	){
		_setRootDirectory( arguments.rootDirectory );
		_setTrashDirectory( arguments.trashDirectory );
		_setPrivateDirectory( arguments.privateDirectory );
		_setRootUrl( arguments.rootUrl );

		return this;
	}

// PUBLIC API METHODS
	public any function validate( required struct configuration, required any validationResult ) {
		var rootDirectory    = arguments.configuration.rootDirectory    ?: "";
		var privateDirectory = arguments.configuration.privateDirectory ?: "";
		var trashDirectory   = arguments.configuration.trashDirectory   ?: "";

		try {
			_ensureDirectoryExists( rootDirectory );
		} catch( any e ) {
			arguments.validationResult.addError(
				  fieldName = "rootDirectory"
				, message   = "storage-providers.filesystem:error.creating.directory"
				, params    = [ rootDirectory, e.message ?: "" ]
			);
		}

		try {
			_ensureDirectoryExists( trashDirectory );
		} catch( any e ) {
			arguments.validationResult.addError(
				  fieldName = "trashDirectory"
				, message   = "storage-providers.filesystem:error.creating.directory"
				, params    = [ trashDirectory, e.message ?: "" ]
			);
		}

		try {
			_ensureDirectoryExists( privateDirectory );
		} catch( any e ) {
			arguments.validationResult.addError(
				  fieldName = "privateDirectory"
				, message   = "storage-providers.filesystem:error.creating.directory"
				, params    = [ privateDirectory, e.message ?: "" ]
			);
		}

	}

	public boolean function objectExists( required string path, boolean trashed=false, boolean private=false ){
		return FileExists( _expandPath( arguments.path, arguments.trashed, arguments.private, true ) );
	}

	public query function listObjects( required string path, boolean private=false ){
		var cleanedPath = _cleanPath( path=arguments.path, private=arguments.private );
		var fullPath    = _expandPath( path=arguments.path, private=arguments.private );
		var objects     = QueryNew( "name,path,size,lastmodified" );
		var files       = "";

		if ( not DirectoryExists( fullPath ) ) {
			return objects;
		}

		files = DirectoryList( fullPath, false, "query" );
		for( var file in files ) {
			if ( file.type eq "File" ) {
				QueryAddRow( objects, {
					  name         = file.name
					, path         = "/" & cleanedPath & file.name
					, size         = file.size
					, lastmodified = file.datelastmodified
				} );
			}
		}

		return objects;
	}

	public binary function getObject( required string path, boolean trashed=false, boolean private=false ){
		try {
			return FileReadBinary( _expandPath( arguments.path, arguments.trashed, arguments.private, true ) );
		} catch ( java.io.FileNotFoundException e ) {
			throw(
				  type    = "storageProvider.objectNotFound"
				, message = "The object, [#arguments.path#], could not be found or is not accessible"
			);
		}
	}

	public struct function getObjectInfo( required string path, boolean trashed=false, boolean private=false ){
		try {
			var info = GetFileInfo( _expandPath( arguments.path, arguments.trashed, arguments.private, true ) );

			return {
				  size         = info.size
				, lastmodified = info.lastmodified
			};
		} catch ( any e ) {
			if ( e.message contains "not exist" ) {
				throw(
					  type    = "storageProvider.objectNotFound"
					, message = "The object, [#arguments.path#], could not be found or is not accessible"
				);
			}

			rethrow;
		}
	}

	public void function putObject( required any object, required string path, boolean private=false ){
		var fullPath = _expandPath( path=arguments.path, private=arguments.private );

		if ( not IsBinary( arguments.object ) and not ( IsSimpleValue( arguments.object ) and FileExists( arguments.object ) ) ) {
			throw(
				  type    = "StorageProvider.invalidObject"
				, message = "The object argument passed to the putObject() method is invalid. Expected either a binary file object or valid file path but received [#SerializeJson( arguments.object )#]"
			);
		}

		_ensureDirectoryExists( GetDirectoryFromPath( fullPath ) );

		if ( IsBinary( arguments.object ) ) {
			FileWrite( fullPath, arguments.object );
		} else {
			FileCopy( arguments.object, fullPath );
		}
	}

	public void function deleteObject( required string path, boolean trashed=false, boolean private=false ){
		try {
			var expandedPath = _expandPath( arguments.path, arguments.trashed, arguments.private, true );
			var dir          = GetDirectoryFromPath( expandedPath );

			FileDelete( expandedPath );
		} catch ( any e ) {
			if ( !( e.message contains "does not exist" ) ) {
				rethrow;
			}
		}

		_deleteEmptyDirs( dir );
	}

	public string function softDeleteObject( required string path, boolean private=false ){
		var fullPath      = _expandPath( path=arguments.path, private=arguments.private, detectLegacyLowerCase=true );
		var newPath       = CreateUUId() & ".trash";
		var fullTrashPath = _getTrashDirectory() & newPath;

		try {
			FileMove( fullPath, fullTrashPath );

			try {
				_deleteEmptyDirs( GetDirectoryFromPath( fullPath ) );
			} catch( any e ){}

			return newPath;
		} catch ( any e ) {
			if ( e.message contains "does not exist" ) {
				return "";
			}

			rethrow;
		}
	}

	public boolean function restoreObject( required string trashedPath, required string newPath, boolean private=false ){
		var fullTrashedPath   = _expandPath( path=arguments.trashedPath, trashed=true, detectLegacyLowerCase=true );
		var fullNewPath       = _expandPath( path=arguments.newPath, private=arguments.private );
		var trashedFileExists = false;

		try {
			_ensureDirectoryExists( GetDirectoryFromPath( fullNewPath ) );
			FileMove( fullTrashedPath, fullNewPath );
			return objectExists( path=arguments.newPath, private=arguments.private );
		} catch ( any e ) {
			if ( e.message contains "does not exist" ) {
				return false;
			}

			rethrow;
		}
	}

	public string function getObjectUrl( required string path ){
		var rootUrl = _getRootUrl();

		if ( Trim( rootUrl ).len() ) {
			return rootUrl & _cleanPath( path=arguments.path, detectLegacyLowerCase=true );
		}

		return "";
	}

// PRIVATE HELPERS
	private string function _getRootPath( boolean trashed=false, boolean private=false ) {
		return arguments.trashed ? _getTrashDirectory() : ( arguments.private ? _getPrivateDirectory() : _getRootDirectory() );
	}

	private string function _expandPath( required string path, boolean trashed=false, boolean private=false, boolean detectLegacyLowerCase=false ){
		var relativePath = _cleanPath( arguments.path, arguments.trashed, arguments.private, arguments.detectLegacyLowerCase );
		var rootPath     = _getRootPath( argumentCollection=arguments );

		return rootPath & relativePath;
	}

	private string function _cleanPath( required string path, boolean trashed=false, boolean private=false, boolean detectLegacyLowerCase=false ){
		var cleaned = ListChangeDelims( arguments.path, "/", "\" );

		cleaned = ReReplace( cleaned, "^/", "" );
		cleaned = Trim( cleaned );

		if ( arguments.detectLegacyLowerCase && !FileExists( _getRootPath( argumentCollection=arguments ) & cleaned ) ) {
			cleaned = LCase( cleaned );
			systemoutput( cleaned );
		}

		return cleaned;
	}

	private void function _ensureDirectoryExists( required string dir ){
		if ( arguments.dir.len() && !DirectoryExists( arguments.dir ) ) {
			try {
				DirectoryCreate( arguments.dir, true, true );
			} catch( any e ) {
				if ( !DirectoryExists( arguments.dir ) ) {
					rethrow;
				}
			}
		}
	}

	public void function moveObject( required string originalPath, required string newPath, boolean originalIsPrivate=false, boolean newIsPrivate=false ) {
		var fullOriginalPath = _expandPath( path=arguments.originalPath, private=arguments.originalIsPrivate, detectLegacyLowerCase=true );
		var fullNewPath      = _expandPath( path=arguments.newPath     , private=arguments.newIsPrivate      );

		try {
			_ensureDirectoryExists( GetDirectoryFromPath( fullNewPath ) );
			FileMove( fullOriginalPath, fullNewPath );
			_deleteEmptyDirs( GetDirectoryFromPath( fullOriginalPath ) );
		} catch( any e ) {
			throw( type="preside.FileSystemStorageProvider.could.not.move", message="Could not move file, [#fullOriginalPath#] to [#fullnewPath#]. Error message: [#e.message#]", detail=e.detail );
		}
	}

// PRIVATE HELPERS
	private void function _deleteEmptyDirs( required string dir ) {
		if ( _isRootDir( arguments.dir ) || _dirHasFiles( arguments.dir ) ) {
			return;
		}

		try {
			DirectoryDelete( dir, false );
			_deleteEmptyDirs( ListDeleteAt( dir, ListLen( dir, "\/" ), "\/" ) );
		} catch( any e ) {
			return;
		}
	}

	private boolean function _isRootDir( required string dir ) {
		var rootDirs = {
			  trash   = LCase( ReReplaceNoCase( _getTrashDirectory(), "[\\/]$", "" ) )
			, root    = LCase( ReReplaceNoCase( _getRootDirectory(), "[\\/]$", "" ) )
			, private = LCase( ReReplaceNoCase( _getPrivateDirectory(), "[\\/]$", "" ) )
		};

		arguments.dir = ReReplaceNoCase( arguments.dir, "[\\/]$", "" );

		for( var rootDirName in rootDirs ) {
			var rootDir = rootDirs[ rootDirName ];
			if ( rootDir.startsWith( LCase( arguments.dir ) ) || rootDir == LCase( arguments.dir ) ) {
				return true;
			}
		}

		return false;
	}

	private boolean function _dirHasFiles( required string dir ) {
		var files = DirectoryList( arguments.dir, false, "path" );

		return files.len() > 0;
	}

// GETTERS AND SETTERS
	private string function _getRootDirectory(){
		return _rootDirectory;
	}
	private void function _setRootDirectory( required string rootDirectory ){
		_rootDirectory = arguments.rootDirectory;
		_rootDirectory = listChangeDelims( _rootDirectory, "/", "\" );
		if ( Right( _rootDirectory, 1 ) != "/" ) {
			_rootDirectory &= "/";
		}
		_ensureDirectoryExists( _rootDirectory );
	}

	private any function _getPrivateDirectory() {
		return _privateDirectory;
	}
	private void function _setPrivateDirectory( required any privateDirectory ) {
		_privateDirectory = arguments.privateDirectory;
		_privateDirectory = listChangeDelims( _privateDirectory, "/", "\" );
		if ( Right( _privateDirectory, 1 ) != "/" ) {
			_privateDirectory &= "/";
		}

		_ensureDirectoryExists( _privateDirectory );
	}

	private string function _getTrashDirectory(){
		return _trashDirectory;
	}
	private void function _setTrashDirectory( required string trashDirectory ){
		_trashDirectory = arguments.trashDirectory;
		_trashDirectory = listChangeDelims( _trashDirectory, "/", "\" );
		if ( Right( _trashDirectory, 1 ) NEQ "/" ) {
			_trashDirectory &= "/";
		}

		_ensureDirectoryExists( _trashDirectory );
	}

	private string function _getRootUrl(){
		return _rootUrl;
	}
	private void function _setRootUrl( required string rootUrl ){
		_rootUrl = arguments.rootUrl;

		if ( Len( Trim( _rootUrl ) ) && Right( _rootUrl, 1 ) != "/" ) {
			_rootUrl &= "/";
		}
	}
}