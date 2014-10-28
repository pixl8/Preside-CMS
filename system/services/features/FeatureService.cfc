/**
 * The Feature Service provides an API to preside's configured features.
 * This allows other systems within PresideCMS to check the enabled statusof enabled
 * status of features before proceeding to provide a page or perform some action
 *
 */
component output=false autodoc=true {

// CONSTRUCTOR
	/**
	 * @configuredFeatures.inject coldbox:setting:features
	 * @siteService.inject        siteService
	 *
	 */
	public any function init( required struct configuredFeatures, required any siteService ) output=false {
		_setSiteService( arguments.siteService );
		_setConfiguredFeatures( arguments.configuredFeatures );
		return this;
	}

// PUBLIC API METHODS
	/**
	 * Returns whether or not the passed feature is currently enabled
	 *
	 * @feature.hint name of the feature to check
	 */
	public boolean function isFeatureEnabled( required string feature ) output=false autodoc=true {
		var features           = _getConfiguredFeatures();
		var activeSiteTemplate = _getSiteService().getActiveSiteTemplate();
		var isEnabled          = IsBoolean( features[ arguments.feature ].enabled ?: "" ) && features[ arguments.feature ].enabled;

		if ( !isEnabled ) {
			return false;
		}

		var availableToTemplates = features[ arguments.feature ].siteTemplates ?: [ "*" ];
		activeSiteTemplate = Len( Trim( activeSiteTemplate ) ) ? activeSiteTemplate : "default";

		return !IsArray( availableToTemplates ) || availableToTemplates.find( "*" ) || availableToTemplates.find( activeSiteTemplate );
	}

// PRIVATE HELPERS

// GETTERS AND SETTERS
	private struct function _getConfiguredFeatures() output=false {
		return _configuredFeatures;
	}
	private void function _setConfiguredFeatures( required struct configuredFeatures ) output=false {
		_configuredFeatures = arguments.configuredFeatures;
	}

	private any function _getSiteService() output=false {
		return _siteService;
	}
	private void function _setSiteService( required any SsteService ) output=false {
		_siteService = arguments.SsteService;
	}

}