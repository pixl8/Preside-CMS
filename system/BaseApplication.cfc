component output=false {
	this.name              = ExpandPath( "/" );
	this.sessionManagement = true;
	this.sessionTimeout    = CreateTimeSpan( 0, 0, 40, 0 );

	_setupMappings();

// APPLICATION LIFECYCLE EVENTS
	public boolean function onApplicationStart() output=false {
		_initEveryEverything();

		return true;
	}

	public boolean function onRequestStart( required string targetPage ) output=true {
		_setupInjectedDatasource();
		_readHttpBodyNowBecauseRailoSeemsToBeSporadicallyBlankingItFurtherDownTheRequest();
		_reloadCheck();

		return application.cbBootstrap.onRequestStart( arguments.targetPage );
	}

	public boolean function onRequest() output=true {
		// ensure all rquests go through coldbox and requested templates cannot be included directly
		return true;
	}

	public void function onApplicationEnd( required struct appScope ) output=false {
		if ( StructKeyExists( arguments.appScope, "cbBootstrap" ) ) {
			arguments.appScope.cbBootstrap.onApplicationEnd( argumentCollection=arguments );
		}
	}

	public void function onSessionStart() output=false {
		if ( StructKeyExists( arguments, "cbBootstrap" ) ) {
			application.cbBootstrap.onSessionStart();
		}
	}

	public void function onSessionEnd( required struct sessionScope, required struct appScope ) output=false {
		if ( StructKeyExists( arguments.appScope, "cbBootstrap" ) ) {
			arguments.appScope.cbBootstrap.onSessionEnd( argumentCollection=arguments );
		}
	}

	public boolean function onMissingTemplate( required string template ) output=false {
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
			thread name=CreateUUId() e=arguments.exception {
				new preside.system.services.errors.ErrorLogService().raiseError( attributes.e );
			}

			content reset=true;
			header statuscode=500;

			if ( FileExists( ExpandPath( "/500.htm" ) ) ) {
				Writeoutput( FileRead( ExpandPath( "/500.htm" ) ) );
			} else {
				Writeoutput( FileRead( "/preside/system/html/500.htm" ) );
			}

			return;
		}
	}

// PRIVATE HELPERS
	private void function _setupMappings() output=false {
		this.mappings[ "/app"     ] = ExpandPath( "/application/" );
		this.mappings[ "/assets"  ] = ExpandPath( "/assets/" );
		this.mappings[ "/logs"    ] = ExpandPath( "/logs/" );
		this.mappings[ "/coldbox" ] = ExpandPath( "/preside/system/externals/coldbox" );
		this.mappings[ "/sticker" ] = ExpandPath( "/preside/system/externals/sticker" );
	}

	private void function _initEveryEverything() output=false {
		setting requesttimeout=1200;

		_fetchInjectedSettings();
		_setupInjectedDatasource();
		_initColdBox();
	}

	private void function _initColdBox() output=false {
		var bootstrap = new preside.system.coldboxModifications.Bootstrap(
			  COLDBOX_CONFIG_FILE   = _discoverConfigPath()
			, COLDBOX_APP_ROOT_PATH = variables.COLDBOX_APP_ROOT_PATH ?: ExpandPath( "/app" )
			, COLDBOX_APP_KEY       = variables.COLDBOX_APP_KEY       ?: ExpandPath( "/app" )
			, COLDBOX_APP_MAPPING   = variables.COLDBOX_APP_MAPPING   ?: "/app"
		);

		bootstrap.loadColdbox();

		application.cbBootstrap = bootstrap;
	}

	private void function _reloadCheck() output=false {
		var reloadRequired = not StructKeyExists( application, "cbBootstrap" ) or application.cbBootStrap.isfwReinit();

		if ( reloadRequired ) {
			_initEveryEverything();
		}
	}

	private void function _fetchInjectedSettings() output=false {
		var settingsManager = new preside.system.services.configuration.InjectedConfigurationManager( app=this, configurationDirectory="/app/config" );
		var config          = settingsManager.getConfig();

		application.injectedConfig = config;
	}

	private void function _setupInjectedDatasource() output=false {
		var config      = application.injectedConfig ?: {};
		var dsnInjected = Len( Trim( config[ "datasource.user" ] ?: "" ) ) && Len( Trim( config[ "datasource.database_name" ] ?: "" ) ) && Len( Trim( config[ "datasource.host" ] ?: "" ) ) && Len( Trim( config[ "datasource.password" ] ?: "" ) );

		if ( dsnInjected ) {
			var dsn        = config[ "datasource.name" ] ?: "preside";
			var useUnicode = config[ "datasource.character_encoding" ] ?: true;

			this.datasources[ dsn ] = {
				  type     : 'MySQL'
				, port     : config[ "datasource.port"          ] ?: 3306
				, host     : config[ "datasource.host"          ]
				, database : config[ "datasource.database_name" ]
				, username : config[ "datasource.user"          ]
				, password : config[ "datasource.password"      ]
				, custom   : {
					  characterEncoding : config[ "datasource.character_encoding" ] ?: "UTF-8"
					, useUnicode        : ( IsBoolean( useUnicode ) && useUnicode )
				  }
			};
		}
	}

	private string function _discoverConfigPath() output=false {
		if ( StructKeyExists( variables, "COLDBOX_CONFIG_FILE" ) ) {
			return variables.COLDBOX_CONFIG_FILE;
		}

		if ( FileExists( "/app/config/LocalConfig.cfc" ) ) {
			return "app.config.LocalConfig";
		}

		if ( FileExists( "/app/config/Config.cfc" ) ) {
			return "app.config.Config";
		}

		return "preside.system.config.Config";
	}

	private void function _readHttpBodyNowBecauseRailoSeemsToBeSporadicallyBlankingItFurtherDownTheRequest() output=false {
		request.http = { body = ToString( GetHttpRequestData().content ) };
	}

	private boolean function _showErrors() output=false {
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

	private any function _getColdboxController() output=false {
		if ( StructKeyExists( application, "cbBootstrap" ) && IsDefined( 'application.cbBootstrap.getController' ) ) {
			return application.cbBootstrap.getController();
		}

		return;
	}

	private boolean function _dealWithSqlReloadProtectionErrors( required struct exception ) output=true {
		var exceptionType = ( arguments.exception.type ?: "" );

		if ( exceptionType == "presidecms.auto.schema.sync.disabled" ) {
			thread name=CreateUUId() e=arguments.exception {
				new preside.system.services.errors.ErrorLogService().raiseError( attributes.e );
			}

			header statuscode=500;content reset=true;
			include template="/preside/system/views/errors/sqlRebuild.cfm";
			return true;
		}

		return false;
	}
}