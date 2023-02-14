/**
 * Service providing ability to read from the system's environment variables
 * and return meaningful configuration for preside.
 *
 * @singleton
 * @autodoc
 *
 */
component displayName="Environment Variables Reader" {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API

	/**
	 * Reads configuration form system environment variables and returns them
	 * as a struct.
	 * \n
	 * Any environment variables whose name begins with PRESIDE_
	 * will be treated as an environment variable intended to be read by the
	 * Preside application. The PRESIDE_ prefix will be stripped from the variable
	 * name before being used. Some examples of environment variable names that
	 * could be used:
	 * \n
	 * ```
	 * PRESIDE_datasource.host=mydb.hostname
	 * PRESIDE_datasource.port=3306
	 * PRESIDE_showerrors=true
	 * PRESIDE_autosyncdb=true
	 * ```
	 *
	 * @autodoc
	 *
	 */
	public struct function getConfigFromEnvironmentVariables() {
		var env        = _getEnv();
		var ignoreKeys = [ "PRESIDE_APPLICATION_ID", "PRESIDE_SERVER_MANAGER_URL", "PRESIDE_SERVER_MANAGER_SERVER_ID", "PRESIDE_SERVER_MANAGER_PUBLIC_KEY", "PRESIDE_SERVER_MANAGER_PRIVATE_KEY" ];
		var config     = {};

		for( var key in env ) {
			if ( key.reFindNoCase( "^PRESIDE_" ) && !ignoreKeys.findNoCase( key ) ) {
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