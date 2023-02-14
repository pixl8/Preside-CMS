/**
 * The Feature Service provides an API to preside's configured features.
 * This allows other systems within Preside to check the enabled status
 * of features before proceeding to provide a page or perform some action.
 *
 */
component singleton=true autodoc=true displayName="Feature service" {

// CONSTRUCTOR
	/**
	 * @configuredFeatures.inject coldbox:setting:features
	 *
	 */
	public any function init( required struct configuredFeatures ) {
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
	public boolean function isFeatureEnabled( required string feature, string siteTemplate ) autodoc=true {
		var features  = _getConfiguredFeatures();
		var isEnabled = IsBoolean( features[ arguments.feature ].enabled ?: "" ) && features[ arguments.feature ].enabled;

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

	/**
	 * Returns whether or not the passed feature is defined at all
	 *
	 * @feature.hint name of the feature to check
	 *
	 */
	public boolean function isFeatureDefined( required string feature ) {
		var features = _getConfiguredFeatures();

		return StructKeyExists( features, arguments.feature );
	}

	/**
	 * Returns the feature that the given widget belongs to.
	 * Returns an empty string if the widget does not belong to a feature
	 *
	 * @autodoc
	 * @widget.hint ID of the widget
	 */
	public string function getFeatureForWidget( required string widget ) {
		var features = _getConfiguredFeatures();

		for( var featureName in features ) {
			var widgets = features[ featureName ].widgets ?: [];

			if ( IsArray( widgets ) && widgets.findNoCase( arguments.widget ) ) {
				return featureName;
			}
		}

		return "";
	}

// GETTERS AND SETTERS
	private struct function _getConfiguredFeatures() {
		return _configuredFeatures;
	}
	private void function _setConfiguredFeatures( required struct configuredFeatures ) {
		_configuredFeatures = arguments.configuredFeatures;
	}
}