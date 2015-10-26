component {

	/**
	 * This extension Config.cfc has been scaffolded by the PresideCMS
	 * Scaffolding service.
	 *
	 * Override or append to core PresideCMS/Coldbox settings here.
	 *
	 */
	public void function configure( required struct config ) {
		// core settings that will effect Preside
		var settings            = arguments.config.settings            ?: {};

		// other ColdBox settings
		var coldbox             = arguments.config.coldbox             ?: {};
		var i18n                = arguments.config.i18n                ?: {};
		var interceptors        = arguments.config.interceptors        ?: {};
		var interceptorSettings = arguments.config.interceptorSettings ?: {};
		var cacheBox            = arguments.config.cacheBox            ?: {};
		var wirebox             = arguments.config.wirebox             ?: {};
		var logbox              = arguments.config.logbox              ?: {};
		var environments        = arguments.config.environments        ?: {};

	}
}