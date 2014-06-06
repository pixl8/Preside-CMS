component extends="coldbox.system.Interceptor" output=false {

// PUBLIC
	public void function configure(){}

	public boolean function onCfStaticInit( event, interceptData ){
		_setCfStaticSettings( interceptData.settings ?: {} );

		if ( _mergeNecessary() ) {
			_mergeAssets();
		}
		_generateI18nFiles();

		return true;
	}

	public boolean function onCfStaticInclude( event, interceptData ){
		_mergeCheck( event );
		return true;
	}

	public boolean function onCfStaticIncludeData( event, interceptData ){
		_mergeCheck( event );
		return true;
	}

	public boolean function onCfStaticRenderIncludes( event, interceptData ){
		_mergeCheck( event );
		return true;
	}

// PRIVATE
	private void function _mergeCheck( event ) {
		if ( !event.isAjax() && _getCfStaticSettings().checkForUpdates ) {
			if ( _mergeNecessary() ) {
				_mergeAssets();
				_generateI18nFiles();
			}
		}
	}

	private void function _mergeAssets(){
		if ( not StructKeyExists( request, '_presideCfStaticAssetsMerged' ) ) {
			var settings      = _getCfStaticSettings();
			var generatedDir  = settings.generatedDirectory;
			var changedAssets = "";
			var asset         = "";
			var sourceDirs    = [ "/preside/system/assets", settings.sourceDirectory ];
			var sourceDir     = "";
			var filePath      = "";
			var targetFile    = "";

			changedAssets = _calculateChangedAssets();

			for( asset in changedAssets.changes ) {
				targetFile = generatedDir & asset;
				_deleteFile( targetFile );

				for( sourceDir in sourceDirs ){
					filePath = sourceDir & asset;
					if ( FileExists( filePath ) ) {
						if ( ListLast( filePath, "\/" ) eq "dependencies.info" and FileExists( targetFile ) ) {
							_appendFile( filePath, targetFile )
						} else {
							_copyFile( filePath, targetFile );
						}
					}
				}
			}
			for( asset in changedAssets.deletions ) {
				filePath = generatedDir & asset;

				_deleteFile( filePath );
			}

			_generateStatusFile();

			request._presideCfStaticAssetsMerged = true;
		}
	}

	private void function _appendFile( required string source, required string destination ) {
		file action="append" file=arguments.destination output=Chr(13) & Chr(10) & FileRead( arguments.source );
	}

	private void function _copyFile( required string source, required string destination ) {
		_createMissingParentDirectories( ExpandPath( arguments.destination ) );
		file action="copy" source=arguments.source destination=arguments.destination;
	}

	private void function _createMissingParentDirectories( required string fileOrDir ) {
		var parent = ListDeleteAt( arguments.fileOrDir, ListLen( arguments.fileOrDir, "\/" ), "\/" );

		if ( not DirectoryExists( parent ) ) {
			_createMissingParentDirectories( parent );
			DirectoryCreate( parent );
		}
	}

	private void function _deleteFile( required string filePath ) {
		if ( FileExists( arguments.filePath ) ) {
			file action="delete" file="#arguments.filePath#";
		}
	}

	private void function _generateI18nFiles(){
		var settings   = _getCfStaticSettings();
		var bundles    = "";
		var bundle     = "";
		var locales    = "";
		var locale     = "";
		var widgetSvc  = getModel( "widgetsService" );
		var poSvc      = getModel( "presideObjectService" );
		var rsSvc      = getModel( "resourceBundleService" );
		var rootFolder = "";
		var newFolder  = "";
		var js         = "";
		var json       = "";

		if ( not StructKeyExists( request, '_presideCfStaticI18nGenerated' ) ) {

			rootFolder = settings.generatedDirectory & "/js/admin/i18n";
			if ( not DirectoryExists( rootFolder ) ) {
				directory action="create" directory=rootFolder;
			}

			bundles = ["cms"];
			for( var widget in widgetSvc.getWidgets() ) {
				ArrayAppend( bundles, "widgets." & widget );
			}
			for( var po in poSvc.listObjects() ) {
				ArrayAppend( bundles, "preside-objects." & po );
			}

			locales = rsSvc.listLocales();
			ArrayAppend( locales, "en" ); // our default locale

			for( locale in locales ) {
				newFolder = rootFolder & "/" & locale;
				if ( not DirectoryExists( newFolder ) ) {
					directory action="create" directory=newFolder;
				}

				js = "var _resourceBundle = ( function(){ var rb = {}, bundle, el;";

				for( bundle in bundles ) {
					json = rsSvc.getBundleAsJson(
						  bundle   = bundle
						, language = ListFirst( locale, "-_" )
						, country  = ListRest( locale, "-_" )
					);

					js &= "bundle = #json#; for( el in bundle ) { rb[el] = bundle[el]; }";
				}

				js &= "return rb; } )();"

				file action="write" file=newFolder & "/bundle.js" output=js;
			}
		}
	}

	private boolean function _mergeNecessary() output=false {
		var lastModified = "";
		var tmp          = "";
		var settings     = _getCfStaticSettings();

		if ( StructKeyExists( request, '_presideCfStaticMergeNeccessary' ) ) {
			return request._presideCfStaticMergeNeccessary;
		}

		request._presideCfStaticMergeNeccessary = false;
		lastModified = _getDirectoryLastModified( settings.generatedDirectory );

		// check core assets
		tmp = _getDirectoryLastModified( "/preside/system/assets" );

		if ( tmp gt lastModified ) {
			request._presideCfStaticMergeNeccessary = true;
			return true;
		}

		// todo, check assets in modules

		// check site assets
		tmp = _getDirectoryLastModified( settings.sourceDirectory );

		if ( tmp gt lastModified ) {
			request._presideCfStaticMergeNeccessary = true;
			return true;
		}

		return request._presideCfStaticMergeNeccessary;
	}

	private date function _getDirectoryLastModified( required string dir ) output=false {
		var filesAndDirs = CreateObject( "java", "java.io.File" ).init( Replace( ExpandPath( dir ), "\", "/", "all" ) ).listFiles();
		var excludedDirs = "\.svn|\.git|\.trash";
		var lastModified = 0;
		var dirModified  = 0;
		var epoch        = "January 1 1970 00:00";

		if ( !IsNull( filesAndDirs ) ) {
			for( var i=1; i <= ArrayLen( filesAndDirs ); i++ ){
				if ( filesAndDirs[i].isDirectory() && !ReFindNoCase( excludedDirs, Replace( filesAndDirs[i].getPath(), "\", "/", "all" ) ) ) {
					dirModified = _getDirectoryLastModified( filesAndDirs[i].getPath() );
					dirModified = DateDiff( "s", epoch, dirModified ) * 1000;

					if ( dirModified > lastModified ) {
						lastModified = dirModified;
					}
				} elseif ( filesAndDirs[i].isFile() && filesAndDirs[i].lastModified() > lastModified ) {
					lastModified = filesAndDirs[i].lastModified();
				}
			}
		}

		return DateAdd( "l", lastModified, epoch );
	}

	private void function _generateStatusFile() output=false {
		var settings     = _getCfStaticSettings();
		var dir          = settings.generatedDirectory;
		var filePath     = dir & "/.status";
		var statusData   = _generateStatus( [dir] );

		FileWrite( filePath, SerializeJson( statusData ) );
	}

	private struct function _generateStatus( required array dirs, struct statusData={}, string relativeTo ) output=false {
		var dir            = "";
		var file           = "";
		var relativePath   = "";
		var updated        = "";
		var epoch          = "January 1 1970 00:00";
		var files          = "";
		var excludedDirs   = "/.svn,/.git/,/min";
		var excludedFiles   = ".status,.cfstaticstatecache";

		for( dir in arguments.dirs ) {
			dir   = Replace( ExpandPath( dir ), "\", "/", "all" );
			files = CreateObject( "java", "java.io.File" ).init( dir ).listFiles();

			if ( IsNull( files ) ) {
				continue;
			}

			for( file in files ){
				relativePath = Replace( file.getPath(), "\", "/", "all" );
				relativePath = Replace( relativePath, relativeTo ?: dir, "" );

				if ( file.isDirectory() ) {
					if ( ListFindNoCase( excludedDirs, relativePath ) ) {
						continue;
					}

					_generateStatus( [ file.getPath() ], statusData, relativeTo ?: dir );
				} elseif ( !ListFindNoCase( excludedFiles, file.getName() ) ) {
					updated      = Int( file.lastModified() / 1000 );

					if ( not StructKeyExists( statusData, relativePath ) or updated > statusData[ relativePath ] ) {
						statusData[ relativePath ] = updated;
					}
				}
			}
		}

		return statusData;
	}

	private struct function _readStatusFromFile() output=false {
		var settings     = _getCfStaticSettings();
		var dir          = settings.generatedDirectory ?: "/_assets";
		var filePath     = dir & "/.status";

		if ( fileExists( filePath ) ) {
			return DeserializeJson( fileRead( filePath ) );
		}

		return {};
	}

	private struct function _calculateChangedAssets() output=false {
		var settings       = _getCfStaticSettings();
		var generatedState = _readStatusFromFile();
		var sourceState    = _generateStatus( [ "/preside/system/assets", settings.sourceDirectory ] ); // todo, add module directories
		var changedAssets  = { changes=[], deletions=[] };
		var asset          = "";

		if ( StructIsEmpty( generatedState ) ) {
			generatedState = _generateStatus( [ settings.generatedDirectory ] );
		}

		for( asset in sourceState ) {
			if ( not StructKeyExists( generatedState, asset ) or sourceState[ asset ] gt generatedState[ asset ] ) {
				ArrayAppend( changedAssets.changes, asset );
			}
		}

		for( asset in generatedState ) {
			if ( not StructKeyExists( sourceState, asset ) ) {
				ArrayAppend( changedAssets.deletions, asset );
			}
		}

		return changedAssets;
	}

	private void function _setCfStaticSettings( required struct settingsFromPlugin ) output=false {
		var siteSettings = super.getController().getSettingStructure();

		_settings = {
			  checkForUpdates    = settingsFromPlugin.checkForUpdates ?: false
			, generatedDirectory = settingsFromPlugin.staticDirectory ?: "/_assets"
			, sourceDirectory    = siteSettings.cfstatic_directory     ?: "/app/assets"
		};
	}

	private struct function _getCfStaticSettings() output=false {
		return _settings;
	}
}