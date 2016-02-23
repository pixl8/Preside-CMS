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
	public any function init( required string rootDirectory, required string trashDirectory, string rootUrl="" ){
		_setRootDirectory( arguments.rootDirectory );
		_setTrashDirectory( arguments.trashDirectory );
		_setRootUrl( arguments.rootUrl );

		return this;
	}

// PUBLIC API METHODS
	public any function validate( required struct configuration, required any validationResult ) {
		var rootDirectory  = arguments.configuration.rootDirectory  ?: "";
		var trashDirectory = arguments.configuration.trashDirectory ?: "";

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
	}

	public boolean function objectExists( required string path, boolean trashed=false ){
		return FileExists( _expandPath( arguments.path, arguments.trashed ) );
	}

	public query function listObjects( required string path ){
		var cleanedPath = _cleanPath( arguments.path );
		var fullPath    = _expandPath( arguments.path );
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

	public binary function getObject( required string path, boolean trashed=false ){
		try {
			return FileReadBinary( _expandPath( arguments.path, arguments.trashed ) );
		} catch ( java.io.FileNotFoundException e ) {
			throw(
				  type    = "storageProvider.objectNotFound"
				, message = "The object, [#arguments.path#], could not be found or is not accessible"
			);
		}
	}

	public struct function getObjectInfo( required string path, boolean trashed=false ){
		try {
			var info = GetFileInfo( _expandPath( arguments.path, arguments.trashed ) );

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

	public void function putObject( required any object, required string path ){
		var fullPath = _expandPath( arguments.path );

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

	public void function deleteObject( required string path, boolean trashed=false ){
		try {
			FileDelete( _expandPath( arguments.path, arguments.trashed ) );
		} catch ( any e ) {
			if ( e.message contains "does not exist" ) {
				return;
			}
			rethrow;
		}
	}

	public string function softDeleteObject( required string path ){
		var fullPath      = _expandPath( arguments.path );
		var newPath       = CreateUUId() & ".trash";
		var fullTrashPath = _getTrashDirectory() & newPath;

		try {
			FileMove( fullPath, fullTrashPath );
			return newPath;
		} catch ( any e ) {
			if ( e.message contains "does not exist" ) {
				return "";
			}

			rethrow;
		}
	}

	public boolean function restoreObject( required string trashedPath, required string newPath ){
		var fullTrashedPath   = _expandPath( arguments.trashedPath, true );
		var fullNewPath       = _expandPath( arguments.newPath );
		var trashedFileExists = false;

		try {
			FileMove( fullTrashedPath, fullNewPath );
			return objectExists( arguments.newPath );
		} catch ( any e ) {
			if ( e.message contains "does not exist" ) {
				return false;
			}

			rethrow;
		}
	}

	public string function getObjectUrl( required string path ){
		return _getRootUrl() & _cleanPath( arguments.path );
	}

// PRIVATE HELPERS
	private string function _expandPath( required string path, boolean trashed=false ){
		var relativePath = _cleanPath( arguments.path, arguments.trashed );

		return ( arguments.trashed ? _getTrashDirectory() : _getRootDirectory() ) & relativePath;
	}

	private string function _cleanPath( required string path, boolean trashed=false ){
		var cleaned = ListChangeDelims( arguments.path, "/", "\" );

		cleaned = ReReplace( cleaned, "^/", "" );
		cleaned = Trim( cleaned );
		if ( !arguments.trashed ) {
			cleaned = LCase( cleaned );
		}

		return cleaned;
	}

	private void function _ensureDirectoryExists( required string dir ){
		if ( arguments.dir.len() && !DirectoryExists( arguments.dir ) ) {
			var parentDir = ListDeleteAt( arguments.dir, ListLen( arguments.dir, "/" ), "/" );
			_ensureDirectoryExists( parentDir );
			DirectoryCreate( arguments.dir );
		}
	}

	public string function getPhysicalPath() {
		return _getRootDirectory();
	}

// GETTERS AND SETTERS
	private string function _getRootDirectory(){
		return _rootDirectory;
	}
	private void function _setRootDirectory( required string rootDirectory ){
		_rootDirectory = arguments.rootDirectory;
		_rootDirectory = listChangeDelims( _rootDirectory, "/", "\" );
		if ( Right( _rootDirectory, 1 ) NEQ "/" ) {
			_rootDirectory &= "/";
		}
		_ensureDirectoryExists( _rootDirectory );
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
		if ( Right( _rootUrl, 1 ) NEQ "/" ) {
			_rootUrl &= "/";
		}
	}
}