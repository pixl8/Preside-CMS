component output=false {
	this.name              = ExpandPath( "/" );
	this.sessionManagement = true;

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
		arguments.appScope.cbBootstrap.onApplicationEnd( argumentCollection=arguments );
	}

	public void function onSessionStart() output=false {
		application.cbBootstrap.onSessionStart();
	}

	public void function onSessionEnd( required struct sessionScope, required struct appScope ) output=false {
		arguments.appScope.cbBootstrap.onSessionEnd( argumentCollection=arguments );
	}

	public boolean function onMissingTemplate( required string template ) output=false {
		return application.cbBootstrap.onMissingTemplate( argumentCollection=arguments );
	}

	public void function onError(  required struct exception, required string eventName ) output=true {
		// if server is configured to show errors, just rethrow
		if ( !_showErrors() ) {
			throw object=arguments.exception;

		// otherwise, log the error and serve a flat html file (if we've made it this far we shouldn't be trying to serve a dynamic 500 template)
		} else {

			thread name=CreateUUId() exception=arguments.exception {
	 			log log="Exception" type="Error" text=SerializeJson( attributes.exception );
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
		this.mappings[ "/coldbox" ] = ExpandPath( "/preside/system/externals/coldbox" );
		this.mappings[ "/sticker" ] = ExpandPath( "/preside/system/externals/sticker" );
	}

	private void function _initEveryEverything() output=false {
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
		var coldboxController  = _getColdboxController();
		var defaultInjected    = IsBoolean( application.injectedConfig.showErrors ?: "" ) && application.injectedConfig.showErrors;

		return IsNull( coldboxController ) ? defaultInjected : coldboxController.getSetting( name="showErrors", defaultValue=defaultInjected );
	}

	private any function _getColdboxController() output=false {
		if ( StructKeyExists( application, "cbBootstrap" ) && IsDefined( 'application.cbBootstrap.getController' ) ) {
			return application.cbBootstrap.getController();
		}

		return;
	}
}