component output=false singleton=true {

// CONSTRUCTOR
	public any function init( required string rootDirectory, required string trashDirectory, required string rootUrl, numeric lockTimeout=5 ) output=false {
		_setRootDirectory( arguments.rootDirectory );
		_setTrashDirectory( arguments.trashDirectory );
		_setRootUrl( arguments.rootUrl );
		_setLockTimeout( arguments.lockTimeout );

		return this;
	}

// PUBLIC API METHODS
	public boolean function objectExists( required string path ) output=false {
		var fullPath = _expandPath( arguments.path );
		var exists   = false;

		lock type="readonly" name=fullPath timeout=_getLockTimeout() {
			exists = FileExists( fullPath );
		}

		return exists;
	}

	public query function listObjects( required string path ) output=false {
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

	public binary function getObject( required string path ) output=false {
		var fullPath  = _expandPath( arguments.path );
		var objBinary = "";
		var exists    = false;

		lock type="readonly" name=fullPath timeout=_getLockTimeout() {
			exists = FileExists( fullPath )
			if ( exists ) {
				objBinary = FileReadBinary( fullPath );
			}
		}

		if ( exists ) {
			return objBinary;
		}

		throw(
			  type    = "storageProvider.objectNotFound"
			, message = "The object, [#arguments.path#], could not be found or is not accessible"
		);
	}

	public struct function getObjectInfo( required string path ) output=false {
		var fullPath = _expandPath( arguments.path );
		var info     = {};

		lock type="readonly" name=fullPath timeout=_getLockTimeout() {
			exists = FileExists( fullPath )
			if ( exists ) {
				info = GetFileInfo( fullPath );
			}
		}

		if ( exists ) {
			return {
				  size         = info.size
				, lastmodified = info.lastmodified
			};;
		}

		throw(
			  type    = "storageProvider.objectNotFound"
			, message = "The object, [#arguments.path#], could not be found or is not accessible"
		);
	}

	public void function putObject( required any object, required string path ) output=false {
		var fullPath = _expandPath( arguments.path );

		if ( not IsBinary( arguments.object ) and not ( IsSimpleValue( arguments.object ) and FileExists( arguments.object ) ) ) {
			throw(
				  type    = "StorageProvider.invalidObject"
				, message = "The object argument passed to the putObject() method is invalid. Expected either a binary file object or valid file path but received [#SerializeJson( arguments.object )#]"
			);
		}

		lock type="exclusive" name=fullPath timeout=_getLockTimeout() {
			_ensureDirectoryExist( GetDirectoryFromPath( fullPath ) );

			if ( IsBinary( arguments.object ) ) {
				FileWrite( fullPath, arguments.object );
			} else {
				FileCopy( arguments.object, fullPath );
			}
		}
	}

	public void function deleteObject( required string path ) output=false {
		var fullPath = _expandPath( arguments.path );

		lock type="exclusive" name=fullPath timeout=_getLockTimeout() {
			if ( FileExists( fullPath ) ) {
				FileDelete( fullPath );
			}
		}
	}

	public string function softDeleteObject( required string path ) output=false {
		var fullPath      = _expandPath( arguments.path );
		var newPath       = "";
		var fullTrashPath = "";

		lock type="exclusive" name=fullPath timeout=_getLockTimeout() {
			if ( FileExists( fullPath ) ) {
				newPath       = CreateUUId() & ".trash";
				fullTrashPath = _getTrashDirectory() & newPath;
				FileMove( fullPath, fullTrashPath );
			}
		}

		return newPath;
	}

	public boolean function restoreObject( required string trashedPath, required string newPath ) output=false {
		var fullTrashedPath   = _expandPath( arguments.trashedPath, _getTrashDirectory() );
		var fullNewPath       = _expandPath( arguments.newPath );
		var trashedFileExists = false;

		lock type="exclusive" name=fullNewPath timeout=_getLockTimeout() {
			trashedFileExists = FileExists( fullTrashedPath );
			if ( trashedFileExists ) {
				FileMove( fullTrashedPath, fullNewPath );
			}
		}

		return trashedFileExists && objectExists( arguments.newPath );
	}

	public string function getObjectUrl( required string path ) output=false {
		return _getRootUrl() & _cleanPath( arguments.path );
	}

// PRIVATE HELPERS
	private string function _expandPath( required string path, string rootDir=_getRootDirectory() ) output=false {
		return arguments.rootDir & _cleanPath( arguments.path );
	}

	private string function _cleanPath( required string path ) output=false {
		var cleaned = ListChangeDelims( arguments.path, "/", "\" );

		cleaned = ReReplace( cleaned, "^/", "" );
		cleaned = Trim( cleaned );
		cleaned = LCase( cleaned );

		return cleaned;
	}

	private void function _ensureDirectoryExist( required string dir ) output=false {
		var parentDir = "";
		if ( not DirectoryExists( arguments.dir ) ) {
			parentDir = ListDeleteAt( arguments.dir, ListLen( arguments.dir, "/" ), "/" );
			_ensureDirectoryExist( parentDir );
			DirectoryCreate( arguments.dir );
		}
	}

// GETTERS AND SETTERS
	private string function _getRootDirectory() output=false {
		return _rootDirectory;
	}
	private void function _setRootDirectory( required string rootDirectory ) output=false {
		_rootDirectory = arguments.rootDirectory;
		_rootDirectory = listChangeDelims( _rootDirectory, "/", "\" );
		if ( Right( _rootDirectory, 1 ) NEQ "/" ) {
			_rootDirectory &= "/";
		}
		_ensureDirectoryExist( _rootDirectory );
	}

	private string function _getTrashDirectory() output=false {
		return _trashDirectory;
	}
	private void function _setTrashDirectory( required string trashDirectory ) output=false {
		_trashDirectory = arguments.trashDirectory;
		_trashDirectory = listChangeDelims( _trashDirectory, "/", "\" );
		if ( Right( _trashDirectory, 1 ) NEQ "/" ) {
			_trashDirectory &= "/";
		}

		_ensureDirectoryExist( _trashDirectory );
	}

	private string function _getRootUrl() output=false {
		return _rootUrl;
	}
	private void function _setRootUrl( required string rootUrl ) output=false {
		_rootUrl = arguments.rootUrl;
		if ( Right( _rootUrl, 1 ) NEQ "/" ) {
			_rootUrl &= "/";
		}
	}

	private numeric function _getLockTimeout() output=false {
		return _lockTimeout;
	}
	private void function _setLockTimeout( required numeric lockTimeout ) output=false {
		_lockTimeout = arguments.lockTimeout;
	}
}