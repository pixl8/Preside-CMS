/**
 * An object to provide configuration fetching for the REST platform
 * dependent on the request context (current resource, etc.).
 *
 * @autodoc
 * @singleton
 *
 */
component {

// CONSTRUCTOR
	/**
	 * @configuration.inject coldbox:setting:rest
	 *
	 */
	public any function init( required struct configuration ) {
		_setConfiguration( arguments.configuration );

		return this;
	}

// PUBLIC API
	/**
	 * Fetches a configuration value from
	 * the configuration based on the currently in use
	 * API and resource
	 *
	 * @autodoc           true
	 * @name.hint         the name of the setting
	 * @defaultValue.hint the name of the setting
	 *
	 */
	public any function getSetting(
		  required string name
		,          string defaultValue = ""
		,          string api          = "/"
	) {
		var configuration    = _getConfiguration();
		var apiSpecificValue = configuration.apis[ arguments.api ][ arguments.name ] ?: NullValue();
		var globalValue      = configuration[ arguments.name ] ?: arguments.defaultValue;

		return apiSpecificValue ?: globalValue;
	}

// PRIVATE GETTERS AND SETTERS
	private struct function _getConfiguration() {
		return _configuration;
	}
	private void function _setConfiguration( required struct configuration ) {
		_configuration = arguments.configuration;
	}
}