/**
 * The injected configuration manager allows configuration to be injected intois designed to work with
 * Preside through the use of environment variables.
 * In addition, the service will attempt to pull configuration from  the Preside Server Manager
 * (which is not part of the core Preside engine - Contact Pixl8 for more details)
 *
 * @autodoc
 * @singleton
 */

component {

// Constructor
	public any function init( required any app, required string appDirectory ) {
		_setApp( arguments.app );
		_setAppDirectory( arguments.appDirectory );
		_setConfigurationDirectory( arguments.appDirectory & "/config" );

		return this;
	}

// public api methods
	/**
	 * Returns a structure of injected configuration. This is a combination of:
	 * \n
	 * 1. Configuration read from [[api-environmentvariablesreader]]
	 * 2. Configuration pulled from Pixl8's Server Manager product
	 * 3. Configuration read from local /app/.env file
	 * 4. Configuration read from local json file /app/config/.injectedConfiguration
	 *
	 * @autodoc
	 *
	 */
	public struct function getConfig() {
		var config        = {};
		var envConfig     = new EnvironmentVariablesReader().getConfigFromEnvironmentVariables();
		var envFileConfig = _readConfigFromEnvFile();
		var remoteConfig  = _fetchConfigFromRemoteServer();

		if ( remoteConfig.isEmpty() ) {
			remoteConfig = _readConfigFromInjectedConfigFile();
		} else {
			_writeConfigToLocalFile( remoteConfig );
		}


		config.append( envConfig );
		config.append( envFileConfig );
		config.append( remoteConfig );

		return config;
	}

// private helpers
	private struct function _fetchConfigFromRemoteServer() {
		var app              = _getApp();
		var applicationId    = app.PRESIDE_APPLICATION_ID             ?: _getEnvironmentVariable( "PRESIDE_APPLICATION_ID"             );
		var serverManagerUrl = app.PRESIDE_SERVER_MANAGER_URL         ?: _getEnvironmentVariable( "PRESIDE_SERVER_MANAGER_URL"         );
		var serverId         = app.PRESIDE_SERVER_MANAGER_SERVER_ID   ?: _getEnvironmentVariable( "PRESIDE_SERVER_MANAGER_SERVER_ID"   );
		var publicKey        = app.PRESIDE_SERVER_MANAGER_PUBLIC_KEY  ?: _getEnvironmentVariable( "PRESIDE_SERVER_MANAGER_PUBLIC_KEY"  );
		var privateKey       = app.PRESIDE_SERVER_MANAGER_PRIVATE_KEY ?: _getEnvironmentVariable( "PRESIDE_SERVER_MANAGER_PRIVATE_KEY" );
		var config           = {};


		if ( Len( Trim( applicationId ) ) && Len( Trim( serverManagerUrl ) ) && Len( Trim( publicKey ) ) && Len( Trim( privateKey ) ) && Len( Trim( serverId ) ) ) {
			config = new preside.system.services.serverManager.PresideServerManagerApiClient( endpoint=serverManagerUrl, publicKey=publicKey, privateKey=privateKey ).getConfig(
				  applicationId = applicationId
				, serverId      = serverId
			);

			if ( !config.isEmpty() ) {
				_writeConfigToLocalFile( config );
			}
		}

		return config;
	}

	private struct function _readConfigFromEnvFile() {
		try {
			var envFileContent = FileRead( _getEnvFilePath() );
		} catch( any e ) {
			return {};
		}

		var lines  = ListToArray( envFileContent, Chr(10) & Chr(13) );
		var key    = "";
		var value  = "";
		var config = {};

		for( var line in lines ) {
			if ( ListLen( line, "=" ) > 1 ) {
				key = Trim( ListFirst( line, "=" ) );
				value = Trim( ListRest( line, "=" ) );

				if ( key.len() ) {
					config[ key ] = value;
				}
			}
		}

		return config;
	}

	private void function _writeConfigToLocalFile( required struct config ) {
		try {
			FileWrite( _getOldSchoolInjectedConfigFilePath(), SerializeJson( config ) );
		} catch ( any e ) {}
	}

	private struct function _readConfigFromInjectedConfigFile() {
		try {
			return DeSerializeJson( FileRead( _getOldSchoolInjectedConfigFilePath() ) );
		} catch ( any e ) {
			return {};
		}
	}

	private string function _getEnvFilePath() {
		return _getAppDirectory() & "/../.env";
	}

	private string function _getOldSchoolInjectedConfigFilePath() {
		return _getConfigurationDirectory() & "/.injectedConfiguration";
	}

	private string function _getEnvironmentVariable( required string variableName ) {
		var result = CreateObject("java", "java.lang.System").getenv().get( arguments.variableName );

		return IsNull( local.result ) ? "" : result;
	}

// getters and setters
	private any function _getApp() {
		return _app;
	}
	private void function _setApp( required any app ) {
		_app = arguments.app;
	}

	private string function _getAppDirectory() {
	    return _appDirectory;
	}
	private void function _setAppDirectory( required string appDirectory ) {
	    _appDirectory = arguments.appDirectory;
	}

	private string function _getConfigurationDirectory() {
		return _configurationDirectory;
	}
	private void function _setConfigurationDirectory( required string configurationDirectory ) {
		_configurationDirectory = arguments.configurationDirectory;
	}
}