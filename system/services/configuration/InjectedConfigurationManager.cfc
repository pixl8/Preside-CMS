/**
 * The injected configuration manager is designed to work with the PresideCMS Server Manager (which is not part of the core PresideCMS engine).
 * The purpose is to receive application confguration details from a remote controller application.
 *
 * Contact Pixl8 for more details.
 *
 */

component output=false {

// Constructor
	public any function init( required any app, required string configurationDirectory ) output=false {
		_setApp( arguments.app );
		_setConfigurationDirectory( arguments.configurationDirectory );

		return this;
	}

// public api methods
	public struct function getConfig() output=false {
		var configuration = _fetchConfigFromRemoteServerAndWriteToLocalFile();

		if ( configuration.isEmpty() ) {
			return _readConfigFromLocalFile();
		}

		return configuration;
	}

// private helpers
	private struct function _fetchConfigFromRemoteServerAndWriteToLocalFile() output=false {
		var app              = _getApp();
		var applicationId    = app.PRESIDE_APPLICATION_ID             ?: _getEnvironmentVariable( "PRESIDE_APPLICATION_ID"             );
		var serverManagerUrl = app.PRESIDE_SERVER_MANAGER_URL         ?: _getEnvironmentVariable( "PRESIDE_SERVER_MANAGER_URL"         );
		var publicKey        = app.PRESIDE_SERVER_MANAGER_PUBLIC_KEY  ?: _getEnvironmentVariable( "PRESIDE_SERVER_MANAGER_PUBLIC_KEY"  );
		var privateKey       = app.PRESIDE_SERVER_MANAGER_PRIVATE_KEY ?: _getEnvironmentVariable( "PRESIDE_SERVER_MANAGER_PRIVATE_KEY" );
		var config           = {};


		if ( Len( Trim( applicationId ) ) && Len( Trim( serverManagerUrl ) ) && Len( Trim( publicKey ) ) && Len( Trim( privateKey ) ) ) {
			config = new preside.system.services.serverManager.PresideServerManagerApiClient( endpoint=serverManagerUrl, publicKey=publicKey, privateKey=privateKey ).getConfig(
				  applicationId = applicationId
				, serverAddress = cgi.remote_addr ?: ""
			);



			if ( !config.isEmpty() ) {
				_writeConfigToLocalFile( config );
			}
		}

		return config;
	}

	private void function _writeConfigToLocalFile( required struct config ) output=false {
		try {
			FileWrite( _getLocalConfigFilePath(), SerializeJson( config ) );
		} catch ( any e ) {}
	}

	private struct function _readConfigFromLocalFile() output=false {
		try {
			return DeSerializeJson( FileRead( _getLocalConfigFilePath() ) );
		} catch ( any e ) {
			return {};
		}
	}

	private string function _getLocalConfigFilePath() output=false {
		return _getConfigurationDirectory() & "/.injectedConfiguration";
	}

	private string function _getEnvironmentVariable( required string variableName ) output=false {
		var result = CreateObject("java", "java.lang.System").getenv().get( arguments.variableName );

		return IsNull( result ) ? "" : result;
	}

// getters and setters
	private any function _getApp() output=false {
		return _app;
	}
	private void function _setApp( required any app ) output=false {
		_app = arguments.app;
	}

	private string function _getConfigurationDirectory() output=false {
		return _configurationDirectory;
	}
	private void function _setConfigurationDirectory( required string configurationDirectory ) output=false {
		_configurationDirectory = arguments.configurationDirectory;
	}
}