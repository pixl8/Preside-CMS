component extends="coldbox.system.Interceptor" output=false {

// PUBLIC
	public void function configure(){}

	public boolean function onCfStaticInit( event, interceptData ){
		_setCfStaticSettings( interceptData.bundle ?: "website", interceptData.settings ?: {} );

		if ( _mergeNecessary( interceptData.bundle ) ) {
			_mergeAssets( interceptData.bundle );
		}
		_generateI18nFiles( interceptData.bundle );

		return true;
	}

	public boolean function onCfStaticInclude( event, interceptData ){
		_mergeCheck( event, interceptData.bundle );
		return true;
	}

	public boolean function onCfStaticIncludeData( event, interceptData ){
		_mergeCheck( event, interceptData.bundle );
		return true;
	}

	public boolean function onCfStaticRenderIncludes( event, interceptData ){
		_mergeCheck( event, interceptData.bundle );
		return true;
	}

// PRIVATE
	private void function _mergeCheck( event, bundle ) {
		if ( !event.isAjax() && _getCfStaticSettings( bundle ).checkForUpdates ) {
			if ( _mergeNecessary( arguments.bundle ) ) {
				_mergeAssets( arguments.bundle );
				_generateI18nFiles( arguments.bundle );
			}
		}
	}

	private void function _mergeAssets( required string bundle ){
		if ( not StructKeyExists( request, '_presideCfStaticAssetsMerged' ) ) {
			var settings      = _getCfStaticSettings( arguments.bundle );
			var generatedDir  = settings.generatedDirectory;
			var changedAssets = "";
			var asset         = "";
			var sourceDirs    = [ "/preside/system/assets/#arguments.bundle#", "/app/assets/#arguments.bundle#" ];
			var sourceDir     = "";
			var filePath      = "";
			var targetFile    = "";

			changedAssets = _calculateChangedAssets( arguments.bundle );

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

			_generateStatusFile( arguments.bundle );

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

	private void function _generateI18nFiles( required string bundle ){
		var settings   = _getCfStaticSettings( arguments.bundle );
		var bundles    = "";
		var b          = "";
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

			rootFolder = settings.generatedDirectory & "/js/i18n";
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

				for( b in bundles ) {
					json = rsSvc.getBundleAsJson(
						  bundle   = b
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

	private boolean function _mergeNecessary( required string bundle ) output=false {
		var lastModified    = "";
		var tmp             = "";
		var settings        = _getCfStaticSettings( arguments.bundle );
		var requestCacheKey = "_presideCfStaticMergeNeccessary" & arguments.bundle;

		if ( StructKeyExists( request, requestCacheKey ) ) {
			return request[ requestCacheKey ];
		}

		request[ requestCacheKey ] = false;

		switch ( settings.merge ) {
			case "never":
				request[ requestCacheKey ] = false;
				return false;
			case "once":
				request[ requestCacheKey ] = !_statusFileExists( arguments.bundle );
				return request[ requestCacheKey ];				
		}

		lastModified = _getDirectoryLastModified( settings.generatedDirectory );

		// check core assets
		tmp = _getDirectoryLastModified( "/preside/system/assets/#arguments.bundle#" );

		if ( tmp gt lastModified ) {
			request[ requestCacheKey ] = true;
			return true;
		}

		// todo, check assets in modules

		// check site assets
		tmp = _getDirectoryLastModified( "/app/assets/#arguments.bundle#" );

		if ( tmp gt lastModified ) {
			request[ requestCacheKey ] = true;
			return true;
		}

		return request[ requestCacheKey ];
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

	private void function _generateStatusFile( required string bundle ) output=false {
		var settings     = _getCfStaticSettings( arguments.bundle );
		var dir          = settings.generatedDirectory;
		var filePath     = dir & "/.status";
		var statusData   = _generateStatus( [dir] );

		FileWrite( filePath, SerializeJson( statusData ) );
	}

	private boolean function _statusFileExists( required string bundle ) output=false {
		var settings     = _getCfStaticSettings( arguments.bundle );
		var dir          = settings.generatedDirectory;
		var filePath     = dir & "/.status";

		return FileExists( filePath );
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

	private struct function _readStatusFromFile( required string bundle ) output=false {
		var settings     = _getCfStaticSettings( arguments.bundle );
		var dir          = settings.generatedDirectory;
		var filePath     = dir & "/.status";

		if ( fileExists( filePath ) ) {
			return DeserializeJson( fileRead( filePath ) );
		}

		return {};
	}

	private struct function _calculateChangedAssets( required string bundle ) output=false {
		var settings       = _getCfStaticSettings( arguments.bundle );
		var generatedState = _readStatusFromFile( arguments.bundle );
		var sourceState    = _generateStatus( [ "/preside/system/assets/#arguments.bundle#", "/app/assets/#arguments.bundle#" ] ); // todo, add module directories
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

	private void function _setCfStaticSettings( required string bundle, required struct settingsFromPlugin ) output=false {
		var siteSettings = super.getController().getSettingStructure();

		_settings = _settings ?: {};
		_settings[ arguments.bundle ] = {
			  checkForUpdates    = settingsFromPlugin.checkForUpdates ?: false
			, generatedDirectory = settingsFromPlugin.staticDirectory ?: "/_assets/#arguments.bundle#"
			, merge              = settingsFromPlugin.merge           ?: "once"
		};
	}

	private struct function _getCfStaticSettings( required string bundle ) output=false {
		return _settings[ arguments.bundle ];
	}
}