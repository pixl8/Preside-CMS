/**
 * Service providing ability to read from the system's environment variables
 * and return meaningful configuration for preside.
 *
 * @singleton
 *
 */
component {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API

	/**
	 * Reads configuration form system environment variables and returns them
	 * as a struct.
	 *
	 */
	public struct function getConfigFromEnvironmentVariables() {
		var env        = _getEnv();
		var ignoreKeys = [ "PRESIDE_APPLICATION_ID", "PRESIDE_SERVER_MANAGER_URL", "PRESIDE_SERVER_MANAGER_SERVER_ID", "PRESIDE_SERVER_MANAGER_PUBLIC_KEY", "PRESIDE_SERVER_MANAGER_PRIVATE_KEY" ];
		var config     = {};

		for( var key in env ) {
			if ( key.startsWith( "PRESIDE_" ) && !ignoreKeys.findNoCase( key ) ) {
				config[ LCase( key.reReplaceNoCase( "^PRESIDE_", "" ) ) ] = env[ key ];
			}
		}

		return config;
	}

// PRIVATE HELPERS
	private any function _getEnv() {
		return CreateObject("java", "java.lang.System").getenv();
	}
}