/**
 * @singleton      true
 * @presideService true
 */
component {

// CONSTRUCTOR
	/**
	 * @bundleDirectories.inject presidecms:directories:i18n
	 * @siteService.inject       featureInjector:sites:siteService
	 * @defaultLocale.inject     coldbox:setting:default_locale
	 */
	public any function init(
		  required array  bundleDirectories
		, required any    siteService
		, required string defaultLocale
	) {
		_setBundleDirectories( arguments.bundleDirectories );
		_setSiteService( arguments.siteService );
		_setDefaultLocale( arguments.defaultLocale );
		_setBundleDataCache( {} );
		_discoverBundles();

		return this;
	}

// PUBLIC API METHODS
	public array function listBundles() output=false {
		return _getBundleNames();
	}

	public array function listLocales( string bundle ) output=false {
		var locales = _getLocales();

		if ( StructKeyExists( arguments, "bundle" ) ) {
			if ( StructKeyExists( locales, arguments.bundle ) ) {
				return locales[ arguments.bundle ];
			}

			return ArrayNew(1);
		}

		return locales._all;
	}

	public string function getResource( required string uri, string defaultValue="", string language, string country ) output=false {
		var bundle      = "";
		var resourceKey = "";
		var bundleData  = "";

		if ( !isValidResourceUri( arguments.uri ) ) {
			return arguments.defaultValue;
		}

		bundle      = ListFirst( arguments.uri, ":" );
		resourceKey = ListRest( arguments.uri, ":" );
		bundleData  = _getBundleData( bundleName=bundle, language=arguments.language, country=arguments.country );

		if ( StructKeyExists( bundleData, resourceKey ) ) {
			return bundleData[ resourceKey ];
		}

		return arguments.defaultValue;
	}

	public string function getBundleAsJson( required string bundle, string language, string country ) output=false {
		var bundleData               = _getBundleData( bundleName=bundle, language=arguments.language, country=arguments.country );
		var key                      = "";
		var dataWithBundleNameInKeys = {};

		for( key in bundleData ) {
			dataWithBundleNameInKeys[ "#arguments.bundle#:#key#" ] = bundleData[ key ];
		}

		return SerializeJson( dataWithBundleNameInKeys );
	}

	public void function reload() output=false {
		_setBundleDataCache( {} );
		_discoverBundles();
	}

	public boolean function isValidResourceUri( required string uri ) {
		var validUriRegex = "[\w][\w-\.]*\:[\w][\w-\.]*[^\.]";

		return ReFind( validUriRegex, arguments.uri ) > 0;
	}


// PRIVATE HELPERS
	private void function _discoverBundles() output=false {
		var directories  = _getBundleDirectories();
		var bundles      = {};
		var files        = "";
		var directory    = "";
		var file         = "";
		var localeRegex  = "(_[a-z]{2})(_[A-Z]{2})?$";
		var bundleName   = "";
		var locales      = { _all = {} };
		var locale       = "";
		var subDirectory = "";

		for( directory in directories ){
			directory = ReReplace( ExpandPath( directory ), "[\\/]$", "" );
			files     = DirectoryList( directory, true, "query", "*.properties" );

			for( file in files ){
				bundleName   = ReReplace( file.name, "\.properties$", "" );

				subDirectory = ReReplace( ReplaceNoCase( file.directory, directory, "" ), "^[\\/]", "" );
				subDirectory = ListChangeDelims( subDirectory, ".", "\/" );
				if ( Len( Trim( subDirectory ) ) ) {
					bundleName = ListAppend( subDirectory, bundleName, "." );
				}

				if ( ReFind( localeRegex, bundleName ) ) {
					locale = ReReplace( bundleName, ("^.*?" & localeRegex ), "\1\2" );
					locale = Right( locale, Len( locale ) - 1 );

					bundleName = ReReplace( bundleName, localeRegex, "" );

					locales._all[ locale ] = 1;
					if ( not StructKeyExists( locales, bundleName ) ) {
						locales[ bundleName ] = {};
					}
					locales[ bundleName ][ locale ] = locales[ bundleName ][ locale ] ?: [];
					ArrayAppend( locales[ bundleName ][ locale ], file.directory & "/" & file.name );
				} else {
					bundles[ bundleName ] = bundles[ bundleName ] ?: [];
					ArrayAppend( bundles[ bundleName ], file.directory & "/" & file.name );
				}
			}
		}
		var defaultLocale = _getDefaultLocale();
		for( var resource in locales ) {
			if ( resource != "_ALL" && StructKeyExists( locales[ resource ], defaultLocale ) ) {
				bundles[ resource ] = bundles[ resource ] ?: [];
				ArrayAppend( bundles[ resource ], locales[ resource ][ defaultLocale ], true );
			}
		}

		_setBundleFileDiscoveryCache( bundles, locales );

		var bundleNames = StructKeyArray( bundles );
		ArraySort( bundleNames, "text" );
		_setBundleNames( bundleNames );

		var localeNames = {};
		localeNames._all = StructKeyArray( locales._all );
		ArraySort( localeNames._all, "text" );
		for( bundleName in bundleNames ){
			if ( StructKeyExists( locales, bundleName ) ) {
				localeNames[ bundleName ] = StructKeyArray( locales[ bundleName ] );
				ArraySort( localeNames[ bundleName ], "text" );
			}
		}

		_setLocales( localeNames );
	}

	private struct function _getBundleData( required string bundleName, string language, string country ) output=false {
		var bundleDataCache    = _getBundleDataCache();
		var activeSiteTemplate = _getActiveSiteTemplate();
		var bundleCacheKey     = activeSiteTemplate & arguments.bundleName;
		var languageCacheKey   = "";
		var countryCacheKey    =  "";

		if ( not StructKeyExists( bundleDataCache, bundleCacheKey  ) ) {
			bundleDataCache[ bundleCacheKey ] = _readBundleData( arguments.bundleName );
		}

		if ( StructKeyExists( arguments, "language" ) ) {
			languageCacheKey =  bundleCacheKey & "_" & arguments.language;
			if ( not StructKeyExists( bundleDataCache,  languageCacheKey ) ) {
				bundleDataCache[ languageCacheKey ] = _readBundleData( arguments.bundleName, arguments.language );
				StructAppend( bundleDataCache[ languageCacheKey ], bundleDataCache[ bundleCacheKey  ], false );
			}

			if ( StructKeyExists( arguments, "country" ) ) {
				countryCacheKey =  languageCacheKey & "_" & arguments.country;
				if ( not StructKeyExists( bundleDataCache,  countryCacheKey ) ) {
					bundleDataCache[ countryCacheKey ] = _readBundleData( arguments.bundleName, arguments.language, arguments.country );
					StructAppend( bundleDataCache[ countryCacheKey ], bundleDataCache[ languageCacheKey  ], false );
				}
			}
		}

		if ( StructKeyExists( arguments, "language" ) ) {
			if ( StructKeyExists( arguments, "country" ) ) {
				return bundleDataCache[ countryCacheKey ];
			}
			return bundleDataCache[ languageCacheKey ];
		}

		return bundleDataCache[ bundleCacheKey ];
	}

	private struct function _readBundleData( required string bundleName, string language, string country ) output=false {
		var bundleData         = {};
		var files              = _getBundleFiles( argumentCollection=arguments );
		var activeSiteTemplate = _getActiveSiteTemplate();

		for( var file in files ){
			var directory = ReReplace( getDirectoryFromPath( file ), "[\\/]$", "" );
			var siteTemplate = _getSiteTemplateFromPath( directory );

			if ( siteTemplate == "*" || siteTemplate == activeSiteTemplate ) {
				StructAppend( bundleData, _propertiesFileToStruct( file ) );
			}
		}

		return bundleData;
	}

	private struct function _propertiesFileToStruct( required string propertiesFile ) output=false {
		var fis          = CreateObject("java","java.io.FileInputStream").init( arguments.propertiesFile );
		var fir          = CreateObject("java","java.io.InputStreamReader").init( fis, "UTF-8" );
		var prb          = CreateObject("java","java.util.PropertyResourceBundle").init( fir );
		var keys         = prb.getKeys();
		var key          = "";
		var returnStruct = {};

		try{
			while( keys.hasMoreElements() ){
				key                 = keys.nextElement();
				returnStruct[ key ] = prb.handleGetObject( key );
			}

		} catch( any e ){
			fis.close();
			rethrow;
		}

		fis.close();

		return returnStruct;
	}

	private string function _getSiteTemplateFromPath( required string path ) output=false {
		var regex = "^.*[\\/]site-templates[\\/]([^\\/]+)/.*$";

		if ( !ReFindNoCase( regex, arguments.path ) ) {
			return "*";
		}

		return ReReplaceNoCase( arguments.path, regex, "\1" );
	}

	private array function _getBundleFiles( required string bundleName, string language, string country ) {
		if ( _isDefaultLocale( argumentCollection=arguments ) ) {
			return variables._bundleFileDiscoveryCache[ arguments.bundleName ] ?: _discoverOutlierBundleFiles( argumentCollection=arguments );
		}

		var languageFiles = variables._localeFileDiscoveryCache[ arguments.bundleName ][ arguments.language ] ?: _discoverOutlierBundleFiles( bundleName=arguments.bundleName, language=arguments.language );
		if ( !StructKeyExists( arguments, "country" ) ) {
			return languageFiles;
		}

		ArrayAppend( languageFiles, variables._localeFileDiscoveryCache[ arguments.bundleName ][ arguments.language & "_" & arguments.country ] ?: _discoverOutlierBundleFiles( argumentCollection=arguments ), true );

		return languageFiles;
	}

	private array function _discoverOutlierBundleFiles( required string bundleName, string language, string country ) {
		var localeRegex     = "(_[a-z]{2})(_[A-Z]{2})?$";
		var shouldWeBother  = ReFind( localeRegex, arguments.bundleName ); // we should only have missed files that accidentally match the language-country suffix pattern
		var discoveredFiles = [];

		if ( shouldWeBother ) {
			var directories        = _getBundleDirectories();
			var activeSiteTemplate = _getActiveSiteTemplate();
			var filePattern        = ListLast( arguments.bundleName, "." );
			var siteTemplate       = "";
			var subDirectory       = "";
			var files              = "";
			var directory          = "";
			var file               = "";

			if ( ListLen( arguments.bundleName, "." ) > 1 ) {
				subDirectory = ListDeleteAt( arguments.bundleName, ListLen( arguments.bundleName, "." ), "." );
				subDirectory = "/" & ListChangeDelims( subDirectory, "/", "." );
			}

			if ( StructKeyExists( arguments, "language" ) ) {
				filePattern &= "_" & LCase( arguments.language );
				if ( StructKeyExists( arguments, "country" ) ) {
					filePattern &= "_" & UCase( arguments.country );
				}
			}

			filePattern &= ".properties";

			for( directory in directories ){
				directory = ReReplace( directory, "[\\/]$", "" );

				siteTemplate = _getSiteTemplateFromPath( directory );

				if ( siteTemplate == "*" || siteTemplate == activeSiteTemplate ) {
					files = DirectoryList( directory & subDirectory, false, "path", "*.properties" );

					for( file in files ){
						if ( filePattern == ListLast( file, "\/" ) ) {
							ArrayAppend( discoveredFiles, file );
						}
					}
				}
			}
		}

		if ( StructKeyExists( arguments, "language" ) ) {
			if ( StructKeyExists( arguments, "country" ) ) {
				variables._localeFileDiscoveryCache[ arguments.bundleName ][ arguments.language & "_" & arguments.country ] = discoveredFiles;
			} else {
				variables._localeFileDiscoveryCache[ arguments.bundleName ][ arguments.language ] = discoveredFiles;
			}
		} else {
			variables._bundleFileDiscoveryCache[ arguments.bundleName ] = discoveredFiles;
		}

		return discoveredFiles;
	}

	private void function _setBundleFileDiscoveryCache( required struct bundles, required struct locales ) {
	    variables._bundleFileDiscoveryCache = arguments.bundles;
	    variables._localeFileDiscoveryCache = arguments.locales;
	}

	private boolean function _isDefaultLocale( string language="", string country="" ) {
		if ( !Len( Trim( arguments.language ) ) ) {
			return true;
		}
		var locale = arguments.language;
		if ( Len( Trim( arguments.country ) ) ) {
			locale &= "_#arguments.country#";
		}

		return locale == _getDefaultLocale();
	}

	private string function _getActiveSiteTemplate() {
		return $isFeatureEnabled( "sites" ) ? _getSiteService().getActiveSiteTemplate( emptyIfDefault=true ) : "";
	}

// GETTERS AND SETTERS
	private array function _getBundleDirectories() output=false {
		return _bundleDirectories;
	}
	private void function _setBundleDirectories( required array bundleDirectories ) output=false {
		_bundleDirectories = arguments.bundleDirectories;
	}

	private any function _getSiteService() output=false {
		return _siteService;
	}
	private void function _setSiteService( required any siteService ) output=false {
		_siteService = arguments.siteService;
	}

	private array function _getBundleNames() output=false {
		return _bundleNames;
	}
	private void function _setBundleNames( required array bundleNames ) output=false {
		_bundleNames = arguments.bundleNames;
	}

	private struct function _getLocales() output=false {
		return _locales;
	}
	private void function _setLocales( required struct locales ) output=false {
		_locales = arguments.locales;
	}

	private struct function _getBundleDataCache() output=false {
		return _bundleDataCache;
	}
	private void function _setBundleDataCache( required struct bundleDataCache ) output=false {
		_bundleDataCache = arguments.bundleDataCache;
	}

	private string function _getDefaultLocale() {
	    return _defaultLocale;
	}
	private void function _setDefaultLocale( required string defaultLocale ) {
	    _defaultLocale = arguments.defaultLocale;
	}
}