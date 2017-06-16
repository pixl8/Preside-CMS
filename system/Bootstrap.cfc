component {

	public void function setupApplication(
		  string  id                           = CreateUUId()
		, string  name                         = arguments.id & ExpandPath( "/" )
		, array   statelessUrlPatterns         = [ "^https?://(.*?)/api/.*" ]
		, array   statelessUserAgentPatterns   = [ "CFSCHEDULE", "(bot\b|crawler\b|baiduspider|80legs|ia_archiver|voyager|curl|wget|yahoo! slurp|mediapartners-google)" ]
		, boolean sessionManagement
		, any     sessionTimeout               = CreateTimeSpan( 0, 0, 40, 0 )
		, numeric applicationReloadTimeout     = 1200
		, numeric applicationReloadLockTimeout = 0
		, string  scriptProtect                = "none"
		, string  reloadPassword               = "true"
		, boolean showDbSyncScripts            = false
	)  {
		this.PRESIDE_APPLICATION_ID                  = arguments.id;
		this.PRESIDE_APPLICATION_RELOAD_LOCK_TIMEOUT = arguments.applicationReloadLockTimeout;
		this.PRESIDE_APPLICATION_RELOAD_TIMEOUT      = arguments.applicationReloadTimeout;
		this.COLDBOX_RELOAD_PASSWORD                 = arguments.reloadPassword;
		this.name                                    = arguments.name;
		this.scriptProtect                           = arguments.scriptProtect;
		this.statelessUrlPatterns                    = arguments.statelessUrlPatterns;
		this.statelessUserAgentPatterns              = arguments.statelessUserAgentPatterns;
		this.statelessRequest                        = isStatelessRequest( _getUrl() );
		this.sessionManagement                       = arguments.sessionManagement ?: !this.statelessRequest;
		this.sessionTimeout                          = arguments.sessionTimeout;
		this.showDbSyncScripts                       = arguments.showDbSyncScripts;

		_setupMappings( argumentCollection=arguments );
		_setupDefaultTagAttributes();
	}

// APPLICATION LIFECYCLE EVENTS
	public boolean function onRequestStart( required string targetPage ) {
		_maintenanceModeCheck();
		_readHttpBodyNowBecauseLuceeSeemsToBeSporadicallyBlankingItFurtherDownTheRequest();

		if ( _reloadRequired() ) {
			_initEveryEverything();
		}

		return application.cbBootstrap.onRequestStart( arguments.targetPage );
	}

	public void function onRequestEnd() {
		_invalidateSessionIfNotUsed();
		_cleanupCookies();
	}

	public void function onAbort() {
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

	public void function onSessionEnd( required struct sessionScope, required struct appScope ) {
		if ( StructKeyExists( arguments.appScope, "cbBootstrap" ) ) {
			arguments.appScope.cbBootstrap.onSessionEnd( argumentCollection=arguments );
		}
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
		this.mappings[ "/coldbox"        ] = presideroot & "/system/externals/coldbox-standalone-3.8.2/coldbox";
		this.mappings[ "/sticker"        ] = presideroot & "/system/externals/sticker";
		this.mappings[ "/spreadsheetlib" ] = presideroot & "/system/externals/lucee-spreadsheet";
		this.mappings[ "/javaloader"     ] = presideroot & "/system/externals/coldbox-standalone-3.8.2/coldbox/system/core/javaloader"

		this.mappings[ arguments.appMapping     ] = arguments.appPath;
		this.mappings[ arguments.assetsMapping  ] = arguments.assetsPath;
		this.mappings[ arguments.logsMapping    ] = arguments.logsPath;

		DirectoryCreate( presideroot & "/tmp", false, true );
		this.mappings[ "/aoptmp" ] = presideroot & "/tmp";

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

		setting requesttimeout=requestTimeout;

		try {
			lock name=lockname type="exclusive" timeout=locktimeout {
				if ( _reloadRequired() ) {
					_announceInterception( "prePresideReload" );

					log file="application" text="Application starting up (fwreinit called, or application starting for the first time).";

					_clearExistingApplication();
					_ensureCaseSensitiveStructSettingsAreActive();
					_fetchInjectedSettings();
					_setupInjectedDatasource();
					_initColdBox();

					_announceInterception( "postPresideReload" );
					log file="application" text="Application start up complete";
				}
			}
		} catch( lock e ) {
			if ( ( e.lockOperation ?: "" ) == "Timeout" ) {
				_friendlyError( e, 503 );
				abort;
			} else {
				rethrow;
			}
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
		if ( !application.keyExists( "cbBootstrap" ) ) {
			return _preventReloadsWhenExistingUpgradeScriptGenerated();
		}

		return application.cbBootStrap.isfwReinit();
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
				throw( type="security", message="PresideCMS could not automatically update Lucee settings to ensure dot notation for structs preserves case (rather than the default behaviour of converting to uppercase). Please either allow open access to admin APIs or change the setting in Lucee server settings." );
			}
		}
	}

	private void function _fetchInjectedSettings() {
		var settingsManager = new preside.system.services.configuration.InjectedConfigurationManager( app=this, configurationDirectory="#COLDBOX_APP_MAPPING#/config" );
		var config          = settingsManager.getConfig();

		application.injectedConfig = config;
	}

	private void function _setupInjectedDatasource() {
		var config      = application.injectedConfig ?: {};
		var dsnInjected = Len( Trim( config[ "datasource.user" ] ?: "" ) ) && Len( Trim( config[ "datasource.database_name" ] ?: "" ) ) && Len( Trim( config[ "datasource.host" ] ?: "" ) );

		if ( dsnInjected ) {
			var dsn                = config[ "datasource.name" ] ?: "preside";
			var host               = config[ "datasource.host" ];
			var port               = config[ "datasource.port" ] ?: 3306;
			var dbName             = config[ "datasource.database_name" ];
			var encoding           = config[ "datasource.character_encoding" ] ?: "UTF-8";
			var username           = config[ "datasource.user"     ];
			var password           = config[ "datasource.password" ] ?: "";
			var luceeAdminPassword = config[ "lucee.admin.password" ] ?: "";

			// use cfadmin tag here; using this.datasources proving to be unreliable
			admin action     = "updateDatasource"
			      type       = "web"
			      classname  = "org.gjt.mm.mysql.Driver"
			      dsn        = "jdbc:mysql://#host#:#port#/#dbName#?useUnicode=true&characterEncoding=#encoding#&useLegacyDatetimeCode=true"
			      name       = dsn
			      newName    = dsn
			      host       = host
			      database   = dbname
			      port       = port
			      dbusername = username
			      dbpassword = password
			      password   = luceeAdminPassword;
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
		var injectedExists    = IsBoolean( application.injectedConfig.showErrors ?: "" );
		var nonColdboxDefault = injectedExists && application.injectedConfig.showErrors;

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
		var allCookies     = resp.getHeaders( "Set-Cookie" );
		var cleanedCookies = [];

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
		var allCookies     = resp.getHeaders( "Set-Cookie" );
		var sessionCookies = [ "CFID", "CFTOKEN" ];

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

			if ( existingCookies.keyExists( cookieName ) ) {
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

	private void function _friendlyError( required any exception, numeric statusCode=500 ) {
		var appMapping     = request._presideMappings.appMapping ?: "/app";
		var appMappingPath = Replace( ReReplace( appMapping, "^/", "" ), "/", ".", "all" );
		var logsMapping    = request._presideMappings.logsMapping ?: "/logs";

		thread name=CreateUUId() e=arguments.exception appMapping=appMapping appMappingPath=appMappingPath logsMapping=logsMapping {
			if ( !application.keyExists( "errorLogService" ) ) {
				application.errorLogService = new preside.system.services.errors.ErrorLogService(
					  appMapping     = attributes.appMapping
					, appMappingPath = attributes.appMappingPath
					, logsMapping    = attributes.logsMapping
					, logDirectory   = attributes.logsMapping & "/rte-logs"
				);
			}
			application.errorLogService.raiseError( attributes.e );
		}

		content reset=true;
		header statuscode=arguments.statusCode;

		if ( FileExists( ExpandPath( "/#arguments.statusCode#.htm" ) ) ) {
			Writeoutput( FileRead( ExpandPath( "/#arguments.statusCode#.htm" ) ) );
		} else {
			Writeoutput( FileRead( "/preside/system/html/#arguments.statusCode#.htm" ) );
		}
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
}
