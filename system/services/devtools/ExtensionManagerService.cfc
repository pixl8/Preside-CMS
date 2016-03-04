component singleton=true {

// CONSTRUCTOR
	/**
	 * @appMapping.inject coldbox:setting:appMapping
	 *
	 */
	public any function init(
		  string appMapping          = "/app"
		, string extensionsDirectory = "#arguments.appMapping#/extensions"
	) {
		_setExtensionsDirectory( arguments.extensionsDirectory );
		_setAppMapping( arguments.appMapping );

		_createExtensionsFileIfItDoesNotExist();

		return this;
	}

// PUBLIC API METHODS
	public array function listExtensions( boolean activeOnly=false ) {
		var extensionList     = _readExtensionsFromFile();
		var presentExtensions = _listPresentExtensions();
		var listed            = [];

		for( var i=extensionList.len(); i>0; i-- ) {
			var extension = extensionList[i];

			var installed = ArrayFind( presentExtensions, extension.name ) != 0;

			if ( arguments.activeOnly && !(extension.active && installed ) ) {
				ArrayDeleteAt( extensionList, i );
			} else {

				listed.append( extension.name );
				extension.installed = installed;
				extension.directory = extension.installed ? _getExtensionsDirectory() & "/" & extension.name : "";

				if ( extension.directory.len() && DirectoryExists( extension.directory ) ) {
					var manifestFilePath = extension.directory & "/manifest.json";

					if ( !FileExists( manifestFilePath ) ) {
						throw( type="ExtensionManager.missingManifest", message="The extension, [#extension.directory#], does not have a manifest file" );
					}
				}
			}
		}

		if ( !arguments.activeOnly ) {
			for( var extension in presentExtensions ) {
				if ( !ArrayFind( listed, extension ) ) {

				   var extensionDir     = _getExtensionsDirectory() & "/" & extension;
				   var manifestFilePath = extensionDir & "/manifest.json";

					if ( Len( Trim( extensionDir ) ) && DirectoryExists( extensionDir ) && !FileExists( manifestFilePath ) ) {
						throw( type="ExtensionManager.missingManifest", message="The extension, [#extensionDir#], does not have a manifest file" );
					}

					extensionList.append( {
						  name      = extension
						, active    = false
						, installed = true
						, priority  = 0
						, directory = _getExtensionsDirectory() & "/" & extension
					} );
				}
			}
		}


		extensionList.sort( function( a, b ){
			if ( a.priority == b.priority ) {
				return a.name == b.name ? 0 : ( a.name > b.name ? 1 : -1 );
			}

			return a.priority < b.priority ? 1 : -1;
		} );

		return extensionList;
	}

	public void function activateExtension( required string extensionName ) {
		var extensions = _readExtensionsFromFile();

		for( var ext in extensions ){
			if ( ext.name eq arguments.extensionName ) {
				ext.active = true;
				_writeExtensionsToFile( extensions );
				return;
			}
		}

		var untrackedExtensions = _listPresentExtensions();
		for( var ext in untrackedExtensions ) {
			if ( ext == arguments.extensionName ) {
				ArrayAppend( extensions, { name=ext, priority=0, active=true } )
				_writeExtensionsToFile( extensions );
				return;
			}
		}

		throw( type="ExtensionManager.missingExtension", message="The extension, [#arguments.extensionName#], could not be found. Present extensions" );
	}

	public void function deactivateExtension( required string extensionName ) {
		var extensions = _readExtensionsFromFile();

		for( var ext in extensions ){
			if ( ext.name eq arguments.extensionName ) {
				ext.active = false;
				_writeExtensionsToFile( extensions );
				return;
			}
		}

		var untrackedExtensions = _listPresentExtensions();
		for( var ext in untrackedExtensions ) {
			if ( ext == arguments.extensionName ) {
				ArrayAppend( extensions, { name=ext, priority=0, active=false } )
				_writeExtensionsToFile( extensions );
				return;
			}
		}

		throw( type="ExtensionManager.missingExtension", message="The extension, [#arguments.extensionName#], could not be found. Extensions present: #SerializeJson( untrackedExtensions )#" );
	}

	public void function uninstallExtension( required string extensionName ) {
		var extensionList     = _readExtensionsFromFile();
		var presentExtensions = _listPresentExtensions();

		for( var extension in extensionList ) {
			if ( extension.name == arguments.extensionName ) {
				ArrayDelete( extensionList, extension );
				_writeExtensionsToFile( extensionList );
				break;
			}
		}

		for( var extension in presentExtensions ) {
			if ( extension == arguments.extensionName ) {
				DirectoryDelete( _getExtensionsDirectory() & "/" & extension, true );
				break;
			}
		}
	}

	public struct function getExtensionInfo( required string extensionNameOrDirectory ) {
		var manifestDir      = DirectoryExists( extensionNameOrDirectory ) ? extensionNameOrDirectory : _getExtensionsDirectory() & "/" & arguments.extensionNameOrDirectory;
		var manifestFilePath = manifestDir & "/manifest.json";
		var fileContent      = "";
		var parsed           = {};

		if ( !DirectoryExists( manifestDir ) ) {
			throw( type="ExtensionManager.missingExtension", message="The extension, [#arguments.extensionNameOrDirectory#], could not be found" );
		}

		if ( !FileExists( manifestFilePath ) ) {
			throw( type="ExtensionManager.missingManifest", message="The extension, [#arguments.extensionNameOrDirectory#], does not have a manifest file" );
		}

		lock name="manifestfileop-#manifestFilePath#" type="exclusive" timeout="10" {
			fileContent = FileRead( manifestFilePath );
		}

		try {
			parsed = DeSerializeJson( fileContent );
		} catch ( any e ) {
			throw( type="ExtensionManager.invalidManifest", message="The extension, [#arguments.extensionNameOrDirectory#], has a manifest file with invalid json" );
		}

		_validateManifest( parsed, extensionNameOrDirectory );

		return {
			  id        = parsed.id
			, title     = parsed.title
			, author    = parsed.author
			, version   = parsed.version
			, changelog = parsed.changelog ?: ""
		};
	}

	public void function installExtension( required string extensionDirectory ) {
		var extensionInfo   = getExtensionInfo( arguments.extensionDirectory );
		var destinationPath = _getExtensionsDirectory() & "/" & extensionInfo.id;
		var extensionList   = _readExtensionsFromFile();

		if ( DirectoryExists( destinationPath ) ) {
			throw( type="ExtensionManager.manifestExists", message="The extension, [#extensionInfo.id#], is already installed" );
		}

		DirectoryCopy( arguments.extensionDirectory, destinationPath, true );

		for( var ext in extensionList ) {
			if ( ext.name eq extensionInfo.id ) {
				return;
			}
		}

		ArrayAppend( extensionList, { name=extensionInfo.id, priority=0, active=false } );
		_writeExtensionsToFile( extensionList );
	}

// PRIVATE HELPERS
	private array function _readExtensionsFromFile() {
		var extensionsFile = _getExtensionsListFilePath();
		var extensions     = "";

		lock name="extfileop-#extensionsFile#" type="exclusive" timeout="10" {
			extensions = DeSerializeJson( FileRead( extensionsFile ) );
		}

		return extensions;
	}

	private array function _listPresentExtensions() {
		var dirs       = DirectoryList( _getExtensionsDirectory(), false, "query" );
		var extensions = [];

		for( var dir in dirs ) {
			if ( dir.type == "Dir" ) {
				extensions.append( dir.name );
			}
		}

		return extensions;
	}

	private void function _writeExtensionsToFile( required array extensions ) {
		var extensionsFile = _getExtensionsListFilePath();

		lock name="extfileop-#extensionsFile#" type="exclusive" timeout="10" {
			FileWrite( extensionsFile, SerializeJson( arguments.extensions ) );
		}
	}

	private string function _getExtensionsListFilePath() {
		return _getExtensionsDirectory() & "/extensions.json";
	}

	private void function _createExtensionsFileIfItDoesNotExist() {
		var extensionsDir = _getExtensionsDirectory();
		var extensionsFile = _getExtensionsListFilePath();

		lock name="extfileop-#extensionsFile#" type="exclusive" timeout="10" {

			if (!directoryExists(extensionsDir)){
				directorycreate(extensionsDir);
			}

			if ( not FileExists( extensionsFile ) ) {
				FileWrite( extensionsFile, "[]" );
			}
		}
	}

	private void function _validateManifest( required any manifest, required string extensionNameOrDirectory ) {
		var missingFields = [];
		var requiredFields = [ "id", "title", "author", "version" ];

		if ( !IsStruct( arguments.manifest ) ) {
			missingFields = requiredFields;
		} else {
			for( var field in requiredFields ){
				if ( !StructKeyExists( arguments.manifest, field ) ) {
					missingFields.append( field );
				}
			}
		}

		if ( missingFields.len() ) {
			var message = "The extension, [#arguments.extensionNameOrDirectory#], has an invalid manifest file. Missing required fields: ";
			var delim   = ""
			for( var field in missingFields ) {
				message &= delim & "[#field#]";
				delim = ", ";
			}
			throw( type="ExtensionManager.invalidManifest", message=message );
		}
	}

// GETTERS AND SETTERS
	private string function _getExtensionsDirectory() {
		return _extensionsDirectory;
	}
	private void function _setExtensionsDirectory( required string extensionsDirectory ) {
		_extensionsDirectory = arguments.extensionsDirectory;
	}

	private string function _getAppMapping() {
		return _appMapping;
	}
	private void function _setAppMapping( required string appMapping ) {
		_appMapping = arguments.appMapping;
	}
}

