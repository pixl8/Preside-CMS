/**
 * The tenancy service provides the mostly invisible logic
 * for auto filtering data based on custom defined tenants.
 *
 * @presideService true
 * @singleton      true
 * @autodoc        true
 */
component displayName="Tenancy service" {

// CONSTRUCTOR
	/**
	 * @tenancyConfig.inject coldbox:setting:tenancy
	 *
	 */
	public any function init( required struct tenancyConfig ) {
		_setTenancyConfig( arguments.tenancyConfig );
		return this;
	}

// PUBLIC API
	public void function injectObjectTenancyProperties( required struct objectMeta ) {
		return;
	}

// GETTERS AND SETTERS
	private struct function _getTenancyConfig() {
		return _tenancyConfig;
	}
	private void function _setTenancyConfig( required struct tenancyConfig ) {
		_tenancyConfig = arguments.tenancyConfig;
	}

}