component output=false {
	this.name              = ExpandPath( "/" );
	this.sessionManagement = true;

	_setupMappings();

// APPLICATION LIFECYCLE EVENTS
	public boolean function onApplicationStart() output=false {
		_initColdBox();
		return true;
	}

	public boolean function onRequestStart( required string targetPage ) output=true {
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

// PRIVATE HELPERS
	private void function _setupMappings() output=false {
		this.mappings[ "/app"     ] = ExpandPath( "/application/" );
		this.mappings[ "/coldbox" ] = ExpandPath( "/preside/system/externals/coldbox" );
		this.mappings[ "/sticker" ] = ExpandPath( "/preside/system/externals/sticker" );
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
			_initColdBox();
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
}