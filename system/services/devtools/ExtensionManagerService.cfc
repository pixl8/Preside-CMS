/**
 * @singleton true
 *
 */
component {

// CONSTRUCTOR
	/**
	 * @appMapping.inject       coldbox:setting:appMapping
	 * @ignoreExtensions.inject coldbox:setting:legacyExtensionsNowInCore
	 *
	 */
	public any function init( string appMapping="/app", array ignoreExtensions=[] ) {
		_readExtensions( arguments.appMapping, arguments.ignoreExtensions );

		return this;
	}

// PUBLIC API METHODS
	public array function listExtensions() {
		return _getExtensions();
	}

	public boolean function extensionExists( required string extensionId ) {
		var mappings = _getMappedExtensions();

		return StructKeyExists( mappings, arguments.extensionId );
	}

	public struct function getExtension( required string extensionId ) {
		var mappings = _getMappedExtensions();

		return mappings[ arguments.extensionId ] ?: {};
	}

	public string function getExtensionDirectory( required string extensionId ) {
		var mappings = _getMappedExtensions();

		return mappings[ arguments.extensionId ].directory ?: "";
	}

	public string function getExtensionComponentPath( required string extensionId ) {
		var mappings = _getMappedExtensions();

		return mappings[ arguments.extensionId ].componentPath ?: "";
	}

	public boolean function isAppExtension( required string extensionId ) {
		var mappings = _getMappedExtensions();

		return StructKeyExists( mappings, arguments.extensionId ) && mappings[ arguments.extensionId ].isAppLocal;
	}


// PRIVATE HELPERS
	private void function _readExtensions( required string appMapping, required array ignoreExtensions ) {
		var appCacheKey = "__presideappExtensions";

		if ( !StructKeyExists( application, appCacheKey ) ) {
			arguments.appMapping = "/" & ReReplace( arguments.appMapping, "^/", "" );

			var appDir        = ExpandPath( appMapping );
			var extensions    = [];
			var args          = arguments;
			var readDir = function( dir, appLocal ) {
				var manifestFiles = DirectoryList( arguments.dir, true, "path", "manifest.json" );

				for( var manifestFile in manifestFiles ) {
					if ( !_isExtensionManifest( manifestFile, arguments.dir ) ) {
						continue;
					}

					var extension = _parseManifest( manifestFile, appMapping );
					if ( !ArrayFindNoCase( args.ignoreExtensions, extension.id ) ) {
						extension.isAppLocal = arguments.appLocal;
						ArrayAppend( extensions, extension );
					}
				}
			};

			readDir( ListAppend( appDir, "extensions"    , _getDirDelimiter() ), false );
			readDir( ListAppend( appDir, "extensions_app", _getDirDelimiter() ), true );


			extensions = _sortExtensions( extensions );
			application[ appCacheKey ] = extensions;
		}

		_setExtensions( application[ appCacheKey ] );
		var mapped = {};
		for( var ext in application[ appCacheKey ] ) {
			mapped[ ext.id ] = ext;
		}
		_setMappedExtensions( mapped );
	}

	private struct function _parseManifest( required string manifestFile, required string appMapping ) {
		var missingFields  = [];
		var requiredFields = [ "id", "title", "author", "version" ];
		var manifest       = "";
		var appDir         = ExpandPath( arguments.appMapping );

		try {
			manifest = DeserializeJson( FileRead( arguments.manifestFile ) );
		} catch ( any e ) {}

		if ( !IsStruct( manifest ) ) {
			missingFields = requiredFields;
		} else {
			for( var field in requiredFields ){
				if ( !StructKeyExists( manifest, field ) ) {
					missingFields.append( field );
				}
			}
		}

		if ( missingFields.len() ) {
			var message = "The extension, [#GetDirectoryFromPath( arguments.manifestFile )#], has an invalid manifest file. Missing required fields: ";
			var delim   = ""
			for( var field in missingFields ) {
				message &= delim & "[#field#]";
				delim = ", ";
			}
			throw( type="ExtensionManager.invalidManifest", message=message );
		}

		manifest.directory     = Replace( Replace( ReReplaceNoCase( GetDirectoryFromPath( arguments.manifestFile ), "[\\/]$", "" ), appDir, appMapping ), "\", "/", "all" );
		manifest.componentPath = Replace( ReReplace( manifest.directory, "^/", "" ), "/", ".", "all" );
		manifest.name          = ListLast( manifest.directory, "\/" );

		if ( manifest.name == "preside-extension" ) {
			manifest.name = ListGetAt( manifest.directory, ListLen( manifest.directory, "\/" )-1, "\/" );
		}

		manifest[ "dependsOn" ] = manifest.dependson ?: [];
		if ( IsSimpleValue( manifest.dependsOn ) ) {
			manifest.dependsOn = [ manifest.dependsOn ];
		} else if ( !IsArray( manifest.dependsOn ) ) {
			manifest.dependsOn = [];
		}

		return manifest;
	}

	private array function _sortExtensions( required array extensions ) {
		var extensionCount = extensions.len();
		var swapped = false;

		do {
			swapped = false;
			for( var i=1; i<=extensionCount-1; i++ ) {
				var extA = extensions[ i ];
				var extB = extensions[ i+1 ];

				if ( ArrayLen( extA.dependsOn ) ) {
					for( var n=i+1; n<=extensionCount; n++ ) {
						var extC = extensions[ n ];

						if ( ArrayFindNoCase( extA.dependsOn, extC.id ) ) {
							ArrayDeleteAt( extensions, n );
							ArrayInsertAt( extensions, i, extC );
							swapped = true;
							break;
						}
					}
				} else if ( extA.id > extB.id && !ArrayFindNoCase( extB.dependsOn, extA.id ) ) {
					var tmp = extB;
					extensions[ i+1 ] = extA;
					extensions[ i ]   = tmp;
					swapped = true;
				}
			}
		} while( swapped );

		return extensions;
	}

	private boolean function _isExtensionManifest( required string manifestPath, required string extensionsDir ) {
		// path should be {extensionsdir}/{extension-id}/manifest.json
		// not an extension manifest if deeper nested than that
		var relativePath = ReReplace( Replace( arguments.manifestPath, arguments.extensionsDir, "" ), "^[\\/]", "" );

		return ListLen( relativePath, "/\" ) == 2;
	}

// GETTERS AND SETTERS
	private string function _getAppDirectory() {
		return _appMapping;
	}

	private void function _setAppDirectory( required string appMapping ) {
		_appMapping = arguments.appMapping;
	}

	private array function _getExtensions() {
		return _extensions;
	}

	private void function _setExtensions( required array extensions ) {
		_extensions = arguments.extensions;
	}

	private struct function _getMappedExtensions() {
		return _dirMappings;
	}

	private void function _setMappedExtensions( required struct dirMappings ) {
		_dirMappings = arguments.dirMappings;
	}

	private string function _getDirDelimiter() {
		if ( IsNull( variables._dirDelimiter ) ) {
			_setDirDelimiter( CreateObject( "java", "java.lang.System" ).getProperty( "file.separator" ) );
		}

		return variables._dirDelimiter;
	}
	private void function _setDirDelimiter( required string dirDelimiter ) {
		variables._dirDelimiter = arguments.dirDelimiter;
	}

// OLD API NO LONGER SUPPORTED
	public void function activateExtension() {
		throw( type="method.no.longer.supported", message="As of Preside 10.9.0, the activateExtension() method is no longer supported" );
	}
	public void function deactivateExtension() {
		throw( type="method.no.longer.supported", message="As of Preside 10.9.0, the deactivateExtension() method is no longer supported" );
	}

	public void function uninstallExtension() {
		throw( type="method.no.longer.supported", message="As of Preside 10.9.0, the uninstallExtension() method is no longer supported" );
	}

	public void function installExtension() {
		throw( type="method.no.longer.supported", message="As of Preside 10.9.0, the installExtension() method is no longer supported" );
	}

	public struct function getExtensionInfo() {
		throw( type="method.no.longer.supported", message="As of Preside 10.9.0, the getExtensionInfo() method is no longer supported" );
	}

}
