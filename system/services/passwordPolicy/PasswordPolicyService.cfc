/**
 * A class that provides methods for dealing with all aspects of password policies
 *
 * @autodoc true
 */
component {

// CONSTRUCTOR
	/**
	 * @featureService.inject featureService
	 * @policyDao.inject      presidecms:object:password_policy
	 */
	public any function init( required any featureService, required any policyDao ) {
		_setFeatureService( arguments.featureService );
		_setPolicyDao( arguments.policyDao );

		return this;
	}

// PUBLIC API
	public array function listStrengths() {
		return [
			  { name="dangerous", minValue="0"  }
			, { name="bad"      , minValue="15" }
			, { name="moderate" , minValue="40" }
			, { name="good"     , minValue="65" }
			, { name="great"    , minValue="80" }
			, { name="awesome"  , minValue="95" }
		];
	}

	public array function listContexts() {
		var contexts = [ "cms" ];

		if ( _getFeatureService().isFeatureEnabled( "websiteUsers" ) ) {
			contexts.append( "website" );
		}

		return contexts;
	}

	public struct function getPolicy( required string context ) {
		var policy = _getPolicyDao().selectData(
			  filter     = { context = arguments.context }
			, selectData = [ "min_strength", "min_length", "min_uppercase", "min_numeric", "min_symbols", "message" ]
		);

		for( var p in policy ) {
			return p;
		}

		return {
			  min_strength  = 0
			, min_length    = 0
			, min_uppercase = 0
			, min_numeric   = 0
			, min_symbols   = 0
			, message       = ""
		};
	}

// GET SET
	private any function _getFeatureService() {
		return _featureService;
	}
	private void function _setFeatureService( required any featureService ) {
		_featureService = arguments.featureService;
	}

	private any function _getPolicyDao() {
		return _policyDao;
	}
	private void function _setPolicyDao( required any policyDao ) {
		_policyDao = arguments.policyDao;
	}
}
