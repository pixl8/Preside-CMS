/**
 * The Feature Service provides an API to preside's configured features.
 * This allows other systems within PresideCMS to check the enabled status
 * of features before proceeding to provide a page or perform some action.
 *
 */
component output=false singleton=true autodoc=true displayName="Feature service" {

// CONSTRUCTOR
	/**
	 * @configuredFeatures.inject coldbox:setting:features
	 *
	 */
	public any function init( required struct configuredFeatures ) output=false {
		_setConfiguredFeatures( arguments.configuredFeatures );
		return this;
	}

// PUBLIC API METHODS
	/**
	 * Returns whether or not the passed feature is currently enabled
	 *
	 * @feature.hint      name of the feature to check
	 * @siteTemplate.hint current active site template - can be used to check features that can be site template specific
	 */
	public boolean function isFeatureEnabled( required string feature, string siteTemplate ) output=false autodoc=true {
		var features           = _getConfiguredFeatures();
		var isEnabled          = IsBoolean( features[ arguments.feature ].enabled ?: "" ) && features[ arguments.feature ].enabled;

		if ( !isEnabled ) {
			return false;
		}

		if ( !StructKeyExists( arguments, "siteTemplate" ) ) {
			return true;
		}

		var activeSiteTemplate   = Len( Trim( arguments.siteTemplate ) ) ? arguments.siteTemplate : "default";
		var availableToTemplates = features[ arguments.feature ].siteTemplates ?: [ "*" ];

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
}