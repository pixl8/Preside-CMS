component {

	public void function setupApplication(
		  string  id                           = CreateUUId()
		, string  name                         = arguments.id & ExpandPath( "/" )
		, array   statelessUrlPatterns         = _getDefaultStatelessUrlPatterns()
		, array   statelessUserAgentPatterns   = _getDefaultStatelessUserAgents()
		, boolean sessionManagement
		, any     sessionTimeout               = CreateTimeSpan( 0, 0, 40, 0 )
		, numeric applicationReloadTimeout     = 1200
		, numeric applicationReloadLockTimeout = 0
		, string  scriptProtect                = "none"
		, string  cookieSameSitePolicy         = "None"  // "None", "Lax" or "Strict"
		, string  reloadPassword               = "true"
		, boolean showDbSyncScripts            = false
		, boolean bufferOutput                 = true
		, boolean allowPingRequests            = false
	)  {

		this.PRESIDE_APPLICATION_ID                  = arguments.id;
		this.PRESIDE_APPLICATION_RELOAD_LOCK_TIMEOUT = arguments.applicationReloadLockTimeout;
		this.PRESIDE_APPLICATION_RELOAD_TIMEOUT      = arguments.applicationReloadTimeout;
		this.COLDBOX_RELOAD_PASSWORD                 = arguments.reloadPassword;
		this.name                                    = arguments.name;
		this.scriptProtect                           = arguments.scriptProtect;
		this.cookieSameSitePolicy                    = arguments.cookieSameSitePolicy;
		this.statelessUrlPatterns                    = arguments.statelessUrlPatterns;
		this.statelessUserAgentPatterns              = arguments.statelessUserAgentPatterns;
		this.statelessRequest                        = isStatelessRequest( _getUrl() );
		this.sessionManagement                       = arguments.sessionManagement ?: !this.statelessRequest;
		this.sessionTimeout                          = arguments.sessionTimeout;
		this.showDbSyncScripts                       = arguments.showDbSyncScripts;
		this.bufferOutput                            = arguments.bufferOutput;
		this.allowPingRequests                       = arguments.allowPingRequests;

		_setupMappings( argumentCollection=arguments );
		_setupDefaultTagAttributes();
	}

// APPLICATION LIFECYCLE EVENTS
	public boolean function onRequestStart( required string targetPage ) {
		_pingCheck();
		_maintenanceModeCheck();
		_readHttpBodyNowBecauseLuceeSeemsToBeSporadicallyBlankingItFurtherDownTheRequest();

		if ( _reloadRequired() ) {
			_initEveryEverything();
		}

		return application.cbBootstrap.onRequestStart( arguments.targetPage );
	}

	public void function onRequestEnd() {
		if ( IsBoolean( request._isPresideReloadRequest ?: "" ) && request._isPresideReloadRequest ) {
			_isReloading( false );
		}

		_invalidateSessionIfNotUsed();
		_cleanupCookies();
	}

	public void function onAbort() {
		if ( IsBoolean( request._isPresideReloadRequest ?: "" ) && request._isPresideReloadRequest ) {
			_isReloading( false );
		}

		_invalidateSessionIfNotUsed();
		_cleanupCookies();
	}

	public boolean function onRequest() output=true {

		// ensure all rquests go through coldbox and requested templates cannot be included directly
		return true;
	}

	public void function onApplicationEnd( required struct appScope ) {
		if ( StructKeyExists( arguments.appScope, "cbBootstrap" ) ) {
			arguments.appScope.cbBootstrap.onApplicationEnd( argumentCollection=arguments );
		}
	}

	public void function onSessionStart() {
		if ( StructKeyExists( arguments, "cbBootstrap" ) ) {
			application.cbBootstrap.onSessionStart();
		}

		_preventSessionFixation();
	}

	public boolean function onMissingTemplate( required string template ) {
		if ( StructKeyExists( application, "cbBootstrap" ) ) {
			return application.cbBootstrap.onMissingTemplate( argumentCollection=arguments );
		}
	}

	public void function onError(  required struct exception, required string eventName ) output=true {
		if ( _dealWithSqlReloadProtectionErrors( arguments.exception ) ) {
			return;
		}

		if ( _showErrors() ) {
			throw object=arguments.exception;


		} else {
			_friendlyError( arguments.exception, 500 );

			return;
		}
	}

// PRIVATE HELPERS
	private void function _setupMappings(
		  string appMapping     = "/app"
		, string assetsMapping  = "/assets"
		, string logsMapping    = "/logs"
		, string appPath        = _getApplicationRoot() & "/application"
		, string assetsPath     = _getApplicationRoot() & "/assets"
		, string logsPath       = _getApplicationRoot() & "/logs"
	) {
		var presideroot = _getPresideRoot();

		this.mappings[ "/preside"        ] = presideroot;
		this.mappings[ "/coldbox"        ] = presideroot & "/system/externals/coldbox";
		this.mappings[ "/sticker"        ] = presideroot & "/system/externals/sticker";
		this.mappings[ "/cfconcurrent"   ] = presideroot & "/system/externals/cfconcurrent";
		this.mappings[ "/spreadsheetlib" ] = presideroot & "/system/externals/lucee-spreadsheet";
		this.mappings[ "/javaloader"     ] = presideroot & "/system/modules/cbjavaloader/models/javaloader";

		this.mappings[ arguments.appMapping     ] = arguments.appPath;
		this.mappings[ arguments.assetsMapping  ] = arguments.assetsPath;
		this.mappings[ arguments.logsMapping    ] = arguments.logsPath;

		variables.COLDBOX_APP_ROOT_PATH = arguments.appPath;
		variables.COLDBOX_APP_KEY       = arguments.appPath;
		variables.COLDBOX_APP_MAPPING   = arguments.appMapping;

		request._presideMappings = {
			  appMapping     = arguments.appMapping
			, assetsMapping  = arguments.assetsMapping
			, logsMapping    = arguments.logsMapping
		};

		_setupCustomTagPath( presideroot );
	}

	private void function _setupCustomTagPath( required string presideroot ) {
		var tagsDir = arguments.presideroot & "/system/customtags";

		this.customTagPaths = ListAppend( this.customTagPaths ?: "", tagsDir );
	}

	private any function _initEveryEverything() {
		var lockName       = "presideapplicationreload" & Hash( GetCurrentTemplatePath() );
		var requestTimeout = this.PRESIDE_APPLICATION_RELOAD_TIMEOUT;
		var lockTimeout    = this.PRESIDE_APPLICATION_RELOAD_LOCK_TIMEOUT;

		if ( _isReloading() ) {
			_stillReloadingError();
		}

		try {
			lock name=lockname type="exclusive" timeout=locktimeout {
				if ( _isReloading() ) {
					_stillReloadingError();
				}
				if ( !_reloadRequired() ) {
					_isReloading( false );
					return;
				}
				setting requesttimeout=requestTimeout;

				request._isPresideReloadRequest = true;
				_isReloading( true );

				SystemOutput( "Preside System Output (#( this.PRESIDE_APPLICATION_ID ?: ( this.name ?: "" ))#) [#DateTimeFormat( Now(), 'yyyy-mm-dd HH:nn:ss' )#]: Application starting up (fwreinit called, or application starting for the first time)." & Chr( 13 ) & Chr( 10 ) );

				_announceInterception( "prePresideReload" );
				_clearExistingApplication();
				_isReloading( true );
				_checkLuceeVersionCompatibility();
				_ensureCaseSensitiveStructSettingsAreActive();
				_applyJavaPropToImproveXalanXmlPerformance();
				_fetchInjectedSettings();
				_setupInjectedDatasource();
				_preserveLocaleCookieIfPresent();
				_initColdBox();
				_announceInterception( "postPresideReload" );

				_isReloading( false );
				SystemOutput( "Preside System Output (#( this.PRESIDE_APPLICATION_ID ?: ( this.name ?: "" ))#) [#DateTimeFormat( Now(), 'yyyy-mm-dd HH:nn:ss' )#]: Application start up complete" & Chr( 13 ) & Chr( 10 ) );
			}
		} catch( any e ) {
			if ( ( e.lockOperation ?: "" ) == "Timeout" ) {
				_stillReloadingError();
			}
			_isReloading( false );
			rethrow;
		}
	}

	private any function _isReloading( boolean set ) {
		if ( StructKeyExists( arguments, "set" ) ) {
			application._preside_reloading = arguments.set;
		} else {
			return application._preside_reloading ?: false;
		}
	}

	private void function _clearExistingApplication() {
		onApplicationEnd( application );
		application.clear();
		request.delete( "cb_requestcontext" );
		SystemCacheClear( "template" );

		if ( ( server.coldfusion.productName ?: "" ) == "Lucee" ) {
			getPageContext().getCFMLFactory().resetPageContext();
		}
	}

	private void function _initColdBox() {
		application.applicationName = this.name;

		var bootstrap = new preside.system.coldboxModifications.Bootstrap(
			  COLDBOX_CONFIG_FILE   = _discoverConfigPath()
			, COLDBOX_APP_ROOT_PATH = variables.COLDBOX_APP_ROOT_PATH
			, COLDBOX_APP_KEY       = variables.COLDBOX_APP_KEY
			, COLDBOX_APP_MAPPING   = variables.COLDBOX_APP_MAPPING
		);

		bootstrap.loadColdbox();

		application.cbBootstrap = bootstrap;
	}

	private boolean function _reloadRequired() {
		if ( !StructKeyExists( application, "cbBootstrap" ) ) {
			return _preventReloadsWhenExistingUpgradeScriptGenerated();
		}

		return application.cbBootStrap.isfwReinit();
	}

	private void function _checkLuceeVersionCompatibility() {
		var versionString = server.lucee.version ?: "";

		if ( ListLen( versionString, "." ) > 3 ) {
			var major = Val( ListGetAt( versionString, 1, "." ) );
			var minor = Val( ListGetAt( versionString, 2, "." ) );
			var patch = Val( ListGetAt( versionString, 3, "." ) );

			if ( major == 5 ) {
				if ( ( minor == 2 && patch < 9 ) || ( minor < 2 ) ) {
					throw(
						  type    = "preside.compatibility.error"
						, message = "Lucee version [#versionString#] has compatibility issues with this Preside release. You must install Lucee version 5.2.9 or greater."
					);
				}
			}
		}
	}

	private void function _ensureCaseSensitiveStructSettingsAreActive() {
		var check         = { sensiTivity=true };
		var caseSensitive = check.keyArray().find( "sensiTivity" );

		if ( !caseSensitive ) {
			var luceeCompilerSettings = "";

			try {
				admin action="getCompilerSettings" returnVariable="luceeCompilerSettings";
				admin action               = "updateCompilerSettings"
				      dotNotationUpperCase = false
				      suppressWSBeforeArg  = luceeCompilerSettings.suppressWSBeforeArg
				      nullSupport          = luceeCompilerSettings.nullSupport
				      templateCharset      = luceeCompilerSettings.templateCharset;
			} catch( security e ) {
				throw( type="security", message="Preside could not automatically update Lucee settings to ensure dot notation for structs preserves case (rather than the default behaviour of converting to uppercase). Please either allow open access to admin APIs or change the setting in Lucee server settings." );
			}
		}
	}

	private void function _applyJavaPropToImproveXalanXmlPerformance() {
		// see https://issues.apache.org/jira/browse/XALANJ-2540
		var propName     = "org.apache.xml.dtm.DTMManager";
		var desiredValue = "org.apache.xml.dtm.ref.DTMManagerDefault";
		var javaSystem   = CreateObject( "java", "java.lang.System" );
		var actualValue  = javaSystem.getProperty( propName );

		if  ( !Len( Trim( local.actualValue ?: "" ) ) ) {
			javaSystem.setProperty( propName, desiredValue );
		}
	}

	private void function _fetchInjectedSettings() {
		var settingsManager = new preside.system.services.configuration.InjectedConfigurationManager( app=this, appDirectory=COLDBOX_APP_MAPPING );
		var config          = settingsManager.getConfig();

		application.env = application.injectedConfig = config;
	}

	private void function _setupInjectedDatasource() {
		var config      = application.injectedConfig ?: {};
		var dsnInjected = Len( Trim( config[ "datasource.user" ] ?: "" ) ) && Len( Trim( config[ "datasource.database_name" ] ?: "" ) ) && Len( Trim( config[ "datasource.host" ] ?: "" ) );

		if ( dsnInjected ) {
			new preside.system.services.database.DatasourceManager().updateDatasource(
				  host                              = config[ "datasource.host"                        ] ?: ""
				, database                          = config[ "datasource.database_name"               ] ?: ""
				, username                          = config[ "datasource.user"                        ] ?: ""
				, name                              = config[ "datasource.name"                        ] ?: "preside"
				, type                              = config[ "datasource.type"                        ] ?: "MySQL"
				, port                              = config[ "datasource.port"                        ] ?: 3306
				, password                          = config[ "datasource.password"                    ] ?: ""
				, timezone                          = config[ "datasource.timezone"                    ] ?: ""
				, ConnectionLimit                   = config[ "datasource.ConnectionLimit"             ] ?: -1
				, ConnectionTimeout                 = config[ "datasource.ConnectionTimeout"           ] ?: 1
				, metaCacheTimeout                  = config[ "datasource.metaCacheTimeout"            ] ?: 60000
				, blob                              = config[ "datasource.blob"                        ] ?: false
				, clob                              = config[ "datasource.clob"                        ] ?: false
				, validate                          = config[ "datasource.validate"                    ] ?: false
				, storage                           = config[ "datasource.storage"                     ] ?: false
				, verify                            = config[ "datasource.verify"                      ] ?: false
				, allowedSelect                     = config[ "datasource.allowedSelect"               ] ?: true
				, allowedInsert                     = config[ "datasource.allowedInsert"               ] ?: true
				, allowedUpdate                     = config[ "datasource.allowedUpdate"               ] ?: true
				, allowedDelete                     = config[ "datasource.allowedDelete"               ] ?: true
				, allowedAlter                      = config[ "datasource.allowedAlter"                ] ?: true
				, allowedDrop                       = config[ "datasource.allowedDrop"                 ] ?: true
				, allowedRevoke                     = config[ "datasource.allowedRevoke"               ] ?: false
				, allowedCreate                     = config[ "datasource.allowedCreate"               ] ?: true
				, allowedGrant                      = config[ "datasource.allowedGrant"                ] ?: false
				, customUseUnicode                  = config[ "datasource.useUnicode"                  ] ?: false
				, customCharacterEncoding           = config[ "datasource.character_encoding"          ] ?: "UTF-8"
				, customUseOldAliasMetadataBehavior = config[ "datasource.useOldAliasMetadataBehavior" ] ?: false
				, customAllowMultiQueries           = config[ "datasource.allowMultiQueries"           ] ?: false
				, customZeroDateTimeBehavior        = config[ "datasource.zeroDateTimeBehavior"        ] ?: "convertToNull"
				, customAutoReconnect               = config[ "datasource.autoReconnect"               ] ?: false
				, customJdbcCompliantTruncation     = config[ "datasource.jdbcCompliantTruncation"     ] ?: false
				, customTinyInt1isBit               = config[ "datasource.tinyInt1isBit"               ] ?: false
				, customUseLegacyDatetimeCode       = config[ "datasource.useLegacyDatetimeCode"       ] ?: false
				, luceeAdminPassword                = config[ "lucee.admin.password"                   ] ?: ""
			);
		}
	}

	private string function _discoverConfigPath() {
		if ( StructKeyExists( variables, "COLDBOX_CONFIG_FILE" ) ) {
			return variables.COLDBOX_CONFIG_FILE;
		}

		var appMappingPath = Replace( ReReplace( COLDBOX_APP_MAPPING, "^/", "" ), "/", ".", "all" );

		if ( FileExists( "#COLDBOX_APP_MAPPING#/config/LocalConfig.cfc" ) ) {
			return "#appMappingPath#.config.LocalConfig";
		}

		if ( FileExists( "#COLDBOX_APP_MAPPING#/config/Config.cfc" ) ) {
			return "#appMappingPath#.config.Config";
		}

		return "preside.system.config.Config";
	}

	private void function _readHttpBodyNowBecauseLuceeSeemsToBeSporadicallyBlankingItFurtherDownTheRequest() {
		request.http = { body = ToString( GetHttpRequestData().content ) };
	}

	private boolean function _showErrors() {
		var coldboxController = _getColdboxController();
		var injectedExists    = IsBoolean( application.env.showErrors ?: "" );
		var nonColdboxDefault = injectedExists && application.env.showErrors;

		if ( !injectedExists ) {
			var localEnvRegexes = this.LOCAL_ENVIRONMENT_REGEX ?: "^local\.,\.local$,^localhost(:[0-9]+)?$,^127.0.0.1(:[0-9]+)?$";
			var host            = cgi.http_host;
			for( var regex in ListToArray( localEnvRegexes ) ) {
				if ( ReFindNoCase( regex, host ) ) {
					nonColdboxDefault = true;
					break;
				}
			}
		}

		return IsNull( coldboxController ) ? nonColdboxDefault : coldboxController.getSetting( name="showErrors", defaultValue=nonColdboxDefault );
	}

	private any function _getColdboxController() {
		if ( StructKeyExists( application, "cbBootstrap" ) && IsDefined( 'application.cbBootstrap.getController' ) ) {
			return application.cbBootstrap.getController();
		}

		return;
	}

	private boolean function _dealWithSqlReloadProtectionErrors( required struct exception ) output=true {
		var exceptionType = ( arguments.exception.type ?: "" );

		if ( exceptionType == "presidecms.auto.schema.sync.disabled" ) {
			thread name=CreateUUId() e=arguments.exception {
				new preside.system.services.errors.ErrorLogService(
					  appMapping     = request._presideMappings.appMapping ?: "/app"
					, appMappingPath = Replace( ReReplace( ( request._presideMappings.appMapping ?: "/app" ), "^/", "" ), "/", ".", "all" )
					, logsMapping    = request._presideMappings.logsMapping ?: "/logs"
					, logDirectory   = logsMapping & "/rte-logs"
				).raiseError( attributes.e );
			}

			try {
				FileWrite( _getSqlUpgradeScriptFilePath(), exception.detail ?: "" );
			} catch( any e ) {}

			var showScript = IsBoolean( this.showDbSyncScripts ?: "" ) && this.showDbSyncScripts;
			header statuscode=503;content reset=true;
			include template="/preside/system/views/errors/sqlRebuild.cfm";
			return true;
		}

		return false;
	}

	private boolean function _preventReloadsWhenExistingUpgradeScriptGenerated() {
		var reloadDemanded = ( url.fwreinit ?: "" ) == this.COLDBOX_RELOAD_PASSWORD;
		var sqlUpgradeFile = _getSqlUpgradeScriptFilePath();

		if ( FileExists( sqlUpgradeFile ) ) {
			if ( reloadDemanded ) {
				FileDelete( sqlUpgradeFile );
				return true;
			}

			var exception  = { detail=FileRead( sqlUpgradeFile ) };
			var showScript = false;
			header statuscode=503;content reset=true;
			include template="/preside/system/views/errors/sqlRebuild.cfm";
			abort;
		}

		return true;
	}

	private void function _pingCheck() {
		if ( !this.allowPingRequests ) {
			var headers     = GetHttpRequestData( false ).headers;
			var contentType = headers[ "Content-Type" ] ?: "";

			if ( contentType == "text/ping" ) {
				header statuscode=204 statustext="No Content";
				abort;
			}
		}
	}

	private void function _maintenanceModeCheck() {
		new preside.system.services.maintenanceMode.MaintenanceModeService().showMaintenancePageIfActive();
	}

	private void function _preventSessionFixation() {
		var appSettings = getApplicationSettings();

		if ( ( appSettings.sessionType ?: "cfml" ) != "j2ee" ) {
			SessionRotate();
		}
	}

	private void function _invalidateSessionIfNotUsed() {
		var applicationSettings  = getApplicationSettings();
		var sessionIsUsed        = false;
		var ignoreKeys           = [ "cfid", "timecreated", "sessionid", "urltoken", "lastvisit", "cftoken" ];
		var keysToBeEmptyStructs = [ "cbStorage", "cbox_flash_scope" ];
		var sessionsEnabled      = IsBoolean( applicationSettings.sessionManagement ) && applicationSettings.sessionManagement;
		if ( sessionsEnabled ) {
			for( var key in session ) {
				if ( ignoreKeys.findNoCase( key ) ) {
					continue;
				}

				if ( keysToBeEmptyStructs.findNoCase( key ) && IsStruct( session[ key ] ) && session[ key ].isEmpty() ) {
					continue;
				}

				sessionIsUsed = true;
				break;
			}
		}

		if ( !sessionIsUsed ) {
			if ( sessionsEnabled ) {
				this.sessionTimeout = CreateTimeSpan( 0, 0, 0, 1 );
			}

			_removeSessionCookies();
		}
	}

	private void function _removeSessionCookies() {
		var pc             = getPageContext();
		var resp           = pc.getResponse();
		var cleanedCookies = [];

		try {
			var allCookies = resp.getHeaders( "Set-Cookie" );
		} catch( "java.lang.AbstractMethodError" e ) {
			// some requests are dummy requests with dummy response objects that do not implement getHeaders()
			return;
		}

		if ( ArrayLen( allCookies ) ) {
			for( var i=1; i <= ArrayLen( allCookies ); i++ ) {
				var cooky = allCookies[ i ];
				if ( !ReFindNoCase( "^(CFID|CFTOKEN|JSESSIONID|SESSIONID)=", cooky ) ) {
					cleanedCookies.append( cooky );
				}
			}

			if ( !cleanedCookies.len() ) {
				if ( !resp.isCommitted() ) {
					_resetHttpResponseWithoutCookies( resp );
				} else {
					resp.setHeader( "Set-Cookie", "empty=cookie;HttpOnly" );
				}
			} else {
				for( var i=1; i <= cleanedCookies.len(); i++ ) {
					if ( i == 1 ) {
						resp.setHeader( "Set-Cookie", cleanedCookies[ i ] );
					} else {
						resp.addHeader( "Set-Cookie", cleanedCookies[ i ] );
					}
				}
			}
		}
	}

	private void function _resetHttpResponseWithoutCookies( required any resp ) {
		var status      = resp.getStatus();
		var contentType = resp.getContentType();
		var encoding    = resp.getCharacterEncoding();
		var locale      = resp.getLocale();
		var headerNames = resp.getHeaderNames().toArray();
		var headers     = {};

		for( var headerName in headerNames ) {
			if ( headerName != "Set-Cookie" ) {
				headers[ headerName ] = resp.getHeaders( headerName );
			}
		}

		resp.reset();
		resp.setStatus( JavaCast( "int", status ) );
		resp.setContentType( contentType );
		resp.setCharacterEncoding( encoding );
		resp.setLocale( locale );

		for( var headerName in headers ) {
			for( var i=1; i<=ArrayLen( headers[ headerName ] ); i++ ){
				if ( i == 1 ) {
					resp.setHeader( headerName, headers[ headerName ][ i ] );
				} else {
					resp.addHeader( headerName, headers[ headerName ][ i ] );
				}
			}
		}
	}


	private void function _cleanupCookies() {
		var pc             = getPageContext();
		var resp           = pc.getResponse();
		var cbController   = _getColdboxController();
		var sessionCookies = [ "CFID", "CFTOKEN" ];

		try {
			var allCookies = resp.getHeaders( "Set-Cookie" );
		} catch( "java.lang.AbstractMethodError" e ) {
			// some requests are dummy requests with dummy response objects that do not implement getHeaders()
			return;
		}

		if ( IsNull( cbController ) || isStatelessRequest( _getUrl() ) ) {
			if ( ArrayLen( allCookies ) ) {
				if ( !resp.isCommitted() ) {
					_resetHttpResponseWithoutCookies( resp );
				} else {
					resp.setHeader( "Set-Cookie", "empty=cookie;HttpOnly" );
				}
			}
			return;
		}

		var sameSitePolicy    = this.cookieSameSitePolicy;
		var sameSiteRegex     = "(^|;|\s)SameSite=#sameSitePolicy#(;|$)";
		var httpRegex         = "(^|;|\s)HttpOnly(;|$)";
		var secureRegex       = "(^|;|\s)Secure(;|$)";
		var cleanedCookies    = [];
		var anyCookiesChanged = false;
		var site              = cbController.getRequestContext().getSite();
		var isSecure          = ( site.protocol ?: "http" ) == "https";

		for( var i=1; i <= ArrayLen( allCookies ); i++ ) {
			var cooky = allCookies[ i ];
			if ( !Len( Trim( cooky ) ) ) {
				continue;
			}

			if ( sessionCookies.findNoCase( cooky.listFirst( "=" ) ) ) {
				cooky = _stripExpiryDateFromCookieToMakeASessionCookie( cooky );
				anyCookiesChanged = true;
			}

			if ( !ReFindNoCase( httpRegex, cooky ) ) {
				cooky = ListAppend( cooky, "HttpOnly", ";" );
				anyCookiesChanged = true;
			}

			if ( isSecure && !ReFindNoCase( secureRegex, cooky ) ) {
				cooky = ListAppend( cooky, "Secure", ";" );
				anyCookiesChanged = true;
			}

			if ( isSecure && !ReFindNoCase( sameSiteRegex, cooky ) ) {
				cooky = ListAppend( cooky, "SameSite=#sameSitePolicy#", ";" );
				anyCookiesChanged = true;
			}

			cleanedCookies.append( cooky );
		}

		anyCookiesChanged = _clearoutDuplicateCookies( cleanedCookies ) || anyCookiesChanged;

		if ( anyCookiesChanged ) {
			resp.setHeader( "Set-Cookie", "" );
			for( var i=1; i <= cleanedCookies.len(); i++ ) {
				if ( i == 1 ) {
					resp.setHeader( "Set-Cookie", cleanedCookies[ i ] );
				} else {
					resp.addHeader( "Set-Cookie", cleanedCookies[ i ] );
				}
			}
		}
	}

	private string function _getPresideRoot() {
		return ExpandPath( "/preside" );
	}

	private boolean function _clearoutDuplicateCookies( required array cookieSet ) {
		var existingCookies = {};
		var anyCleared      = false;

		for( var i=arguments.cookieSet.len(); i>0; i-- ) {
			var cookieName = ListFirst( arguments.cookieSet[ i ], "=" );

			if ( StructKeyExists( existingCookies, cookieName ) ) {
				arguments.cookieSet.deleteAt( i );
				anyCleared = true;
				continue;
			}

			existingCookies[ cookieName ] = 0;
		}

		return anyCleared;
	}

	private string function _getApplicationRoot() {
		return ExpandPath( "/" );
	}

	private void function _stillReloadingError() {
		_friendlyError( errorCode=503 );
		abort;
	}

	private void function _friendlyError( any exception, numeric statusCode=500 ) {
		var appMapping     = request._presideMappings.appMapping ?: "/app";
		var appMappingPath = Replace( ReReplace( appMapping, "^/", "" ), "/", ".", "all" );
		var logsMapping    = request._presideMappings.logsMapping ?: "/logs";

		if ( StructKeyExists( arguments, "exception" ) ) {
			thread name=CreateUUId() e=arguments.exception appMapping=appMapping appMappingPath=appMappingPath logsMapping=logsMapping {
				if ( !StructKeyExists( application, "errorLogService" ) ) {
					application.errorLogService = new preside.system.services.errors.ErrorLogService(
						  appMapping     = attributes.appMapping
						, appMappingPath = attributes.appMappingPath
						, logsMapping    = attributes.logsMapping
						, logDirectory   = attributes.logsMapping & "/rte-logs"
					);
				}
				application.errorLogService.raiseError( attributes.e );
			}
		}

		content reset=true;
		header statuscode=arguments.statusCode;

		if ( !StructKeyExists( application, "error_template_#arguments.statusCode#" ) ) {
			if ( FileExists( ExpandPath( "/#arguments.statusCode#.htm" ) ) ) {
				application[ "error_template_#arguments.statusCode#" ] = FileRead( ExpandPath( "/#arguments.statusCode#.htm" ) );
			} else {
				application[ "error_template_#arguments.statusCode#" ] = FileRead( "/preside/system/html/#arguments.statusCode#.htm" );
			}
		}

		WriteOutput( application[ "error_template_#arguments.statusCode#" ] );
	}

	private void function _setupDefaultTagAttributes() {
		this.tag.function.bufferoutput = false;
		this.tag.location.addToken     = false;
	}

	private void function _announceInterception() {
		var controller = _getColdboxController();

		if ( !IsNull( controller ) ) {
			controller.getInterceptorService().processState( argumentCollection=arguments );
		}
	}

	private boolean function isStatelessRequest( required string fullUrl ) {
		var urlPatterns   = this.statelessUrlPatterns       ?: [];
		var agentPatterns = this.statelessUserAgentPatterns ?: [];
		var userAgent     = cgi.http_user_agent             ?: "";

		for( var pattern in urlPatterns ) {
			if ( arguments.fullUrl.reFindNoCase( pattern ) ) {
				return true;
			}
		}

		for( var pattern in agentPatterns ) {
			if ( userAgent.reFindNoCase( pattern ) ) {
				return true;
			}
		}

		return false;
	}

	private string function _getUrl() {
		var requestData = GetHttpRequestData();
		var requestUrl  = requestData.headers[ 'X-Original-URL' ] ?: "";

		if ( !Len( Trim( requestUrl ) ) ) {
			requestUrl = request[ "javax.servlet.forward.request_uri" ] ?: "";

			if ( !Len( Trim( requestUrl ) ) ) {
				requestUrl = cgi.request_url;
			} else {
				var protocol = "http";

				if( isBoolean( cgi.server_port_secure ) AND cgi.server_port_secure){
					protocol = "https";
				} else {
					protocol = requestData.headers[ "x-forwarded-proto" ] ?: ( requestData.headers[ "x-scheme" ] ?: LCase( ListFirst( cgi.server_protocol, "/" ) ) );
				}

				requestUrl = protocol & "://" & cgi.http_host & requestUrl;
			}
		}

		return requestUrl;
	}

	private string function _getSqlUpgradeScriptFilePath() {
		return ExpandPath( request._presideMappings.logsMapping ?: "/logs" ) & "/sqlupgrade.sql";
	}

	private string function _stripExpiryDateFromCookieToMakeASessionCookie( required string cooky ) {
		var cookieParts = arguments.cooky.listToArray( ";" );
		var stripped    = "";

		for( var part in cookieParts ) {
			if ( !part.reFindNoCase( "^expires" ) ) {
				stripped = stripped.listAppend( part, ";" );
			}
		}

		return stripped;
	}

	private void function _preserveLocaleCookieIfPresent() {
		request.DefaultLocaleFromCookie = cookie.DefaultLocale ?: "";
	}

	private array function _getDefaultStatelessUrlPatterns() {
		if ( !StructKeyExists( application, "_presideDefaultStatelessUrlPatterns" ) ) {
			var _env = server.system.environment ?: {};
			var defaults = [ "^https?://(.*?)/api/.*", "^https?://(.*?)/e/t/.*" ];

			if ( Len( Trim( _env.PRESIDE_STATELESS_URL_PATTERNS ?: "" ) ) ) {
				defaults = ListToArray( _env.PRESIDE_STATELESS_URL_PATTERNS );
			}
			if ( Len( Trim( _env.PRESIDE_ADDITIONAL_STATELESS_URL_PATTERNS ?: "" ) ) ) {
				ArrayAppend( defaults, ListToArray( _env.PRESIDE_ADDITIONAL_STATELESS_URL_PATTERNS ), true );
			}

			application._presideDefaultStatelessUrlPatterns = defaults;
		}

		return application._presideDefaultStatelessUrlPatterns;
	}

	private array function _getDefaultStatelessUserAgents() {
		if ( !StructKeyExists( application, "_presideDefaultStatelessUserAgentPatterns" ) ) {
			var _env = server.system.environment ?: {};
			var defaults = [ "CFSCHEDULE", "(bot\b|crawler\b|spider\b|80legs|ia_archiver|voyager|curl|wget|yahoo! slurp|mediapartners-google)", "Microsoft Outlook", "ms-office", "googleimageproxy", "thunderbird", "healthcheck", "zabbix", "kube-probe" ];

			if ( Len( Trim( _env.PRESIDE_STATELESS_USER_AGENT_PATTERNS ?: "" ) ) ) {
				defaults = ListToArray( _env.PRESIDE_STATELESS_USER_AGENT_PATTERNS );
			}
			if ( Len( Trim( _env.PRESIDE_ADDITIONAL_STATELESS_USER_AGENT_PATTERNS ?: "" ) ) ) {
				ArrayAppend( defaults, ListToArray( _env.PRESIDE_ADDITIONAL_STATELESS_USER_AGENT_PATTERNS ), true );
			}

			application._presideDefaultStatelessUserAgentPatterns = defaults;
		}

		return application._presideDefaultStatelessUserAgentPatterns;
	}
}
