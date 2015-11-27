component output=false {

// CONSTRUCTOR
	/**
	 * @configuredProviders.inject coldbox:setting:storageproviders
	 *
	 */
	public any function init( required any configuredProviders ) {
		_setConfiguredProviders( arguments.configuredProviders );

		return this;
	}

// PUBLIC API METHODS
	public array function listProviders() {
		return _getConfiguredProviders().keyArray();
	}

// PRIVATE HELPERS

// GETTERS AND SETTERS
	private any function _getConfiguredProviders() {
		return _configuredProviders;
	}
	private void function _setConfiguredProviders( required any configuredProviders ) {
		_configuredProviders = arguments.configuredProviders;
	}

}