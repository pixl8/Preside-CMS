/**
 * The Feature Service provides an API to preside's configured features.
 * This allows other systems within Preside to check the enabled status
 * of features before proceeding to provide a page or perform some action.
 *
 */
component singleton=true autodoc=true displayName="Feature service" {


	property name="siteService" inject="delayedInjector:siteService";

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
	 * @feature.hint      name of the feature to check, or logical expression containing features to check, e.g. "(featurex || featurey) && featurez"
	 * @siteTemplate.hint current active site template - can be used to check features that can be site template specific
	 */
	public boolean function isFeatureEnabled( required string feature, string siteTemplate ) autodoc=true {
		if ( _isComplexExpression( Trim( arguments.feature ) ) ) {
			return _processComplexExpression( arguments.feature, arguments.siteTemplate );
		}
		var features  = _getConfiguredFeatures();
		var isEnabled = IsBoolean( features[ arguments.feature ].enabled ?: "" ) && features[ arguments.feature ].enabled;

		if ( !isEnabled ) {
			return false;
		}

		if ( isArray( features[ arguments.feature ].dependsOn ?: "" ) ) {
			for( var f in features[ arguments.feature ].dependsOn ) {
				if ( !isFeatureEnabled( f, arguments.siteTemplate ) ) {
					if ( !Len( arguments.siteTemplate ) ) {
						features[ arguments.feature ].enabled = false; // shortcut future parent lookups
					}
					return false;
				}
			}
		}

		if (    !StructKeyExists( arguments, "siteTemplate" )
			 || ( IsBoolean( request._isPresideReloadRequest ?: "" ) && request._isPresideReloadRequest )
			 || arguments.feature == "sites"
			 || !isFeatureEnabled( "sites" )
		) {
			return true;
		}

		var availableToTemplates = features[ arguments.feature ].siteTemplates ?: [ "*" ];
		if ( !IsArray( availableToTemplates ) || ArrayFind( availableToTemplates, "*" ) ) {
			return true;
		}

		var activeSiteTemplate  = Len( Trim( arguments.siteTemplate ) ) ? arguments.siteTemplate : "default";
		if ( activeSiteTemplate == "_active" ) {
			activeSiteTemplate = siteService.getActiveSiteTemplate();
		}

		return ArrayFind( availableToTemplates, activeSiteTemplate );
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

// PRIVATE HELPERS
	private boolean function _isComplexExpression( filter ) {
		var evalChars        = "|&\(\)!\s";
		var featureNameChars = "a-zA-Z0-9_\-";

		// must contain one ore more special evaluation chars
		// and must ONLY contain feature name chars + evaluation chars
		return ReFind( "[#evalChars#]+", arguments.filter ) && ReFind( "^[#evalChars##featureNameChars#]+$", arguments.filter );
	}

	private boolean function _processComplexExpression( filter, siteTemplate ) {
		var compiled = arguments.filter;
		var features = ReMatch( "\b[a-zA-Z0-9_\-]+\b", arguments.filter );

		ArraySort( features, function( a, b ){
			var lena = Len( arguments.a );
			var lenb = Len( arguments.b );
			return lena == lenb ? 0 : ( lena < lenb ? 1 : -1 );
		} );

		for( var feature in features ) {
			if ( feature != "not" && feature != "and" && feature != "or" ) {
				compiled = ReplaceNoCase( compiled, feature, isFeatureEnabled( feature, arguments.siteTemplate ) ? "true" : "false", "all" );
			}
		}

		try {
			return Evaluate( compiled );
		} catch( any e ) {
			throw( type="preside.feature.bad.expression", message="The feature name expression, [#arguments.filter#], could not be evaluated. Compiler error: [#e.message#]." );
		}
	}

// GETTERS AND SETTERS
	private struct function _getConfiguredFeatures() {
		return _configuredFeatures;
	}
	private void function _setConfiguredFeatures( required struct configuredFeatures ) {
		_configuredFeatures = arguments.configuredFeatures;
	}
}