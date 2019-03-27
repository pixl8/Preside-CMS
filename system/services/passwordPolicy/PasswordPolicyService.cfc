/**
 * A class that provides methods for dealing with all aspects of password policies
 *
 * @singleton
 * @presideService
 */
component displayName="Password Policy Service" {

// CONSTRUCTOR
/**
	 * @featureService.inject           featureService
	 * @passwordStrengthAnalyzer.inject passwordStrengthAnalyzer
	 * @policyDao.inject                presidecms:object:password_policy
	 */
	public any function init( required any featureService, required any passwordStrengthAnalyzer, required any policyDao ) {
		_setFeatureService( arguments.featureService );
		_setPasswordStrengthAnalyzer( arguments.passwordStrengthAnalyzer );
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

	public string function getStrengthNameForScore( required numeric score ) {
		var strengths = listStrengths();

		for( var i=strengths.len(); i > 0; i-- ) {
			if ( arguments.score >= strengths[ i ].minValue ) {
				return strengths[ i ].name;
			}
		}

		return strengths[ 1 ].name;
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

	public void function savePolicy(
		  required string  context
		,          numeric min_strength  = 0
		,          numeric min_length    = 0
		,          numeric min_uppercase = 0
		,          numeric min_numeric   = 0
		,          numeric min_symbols   = 0
		,          string  message       = ""
	) {
		var dao    = _getPolicyDao();
		var filter = { context=arguments.context };

		if ( dao.dataExists( filter=filter ) ) {
			dao.updateData( filter=filter, data=arguments );
		} else {
			dao.insertData( data=arguments );
		}

		$audit(
			  action   = "password_policy_saved"
			, type     = "passwordpolicies"
			, detail   = arguments
			, recordId = arguments.context
		);
	}

	public boolean function passwordMeetsPolicy( required string context, required string password ) {
		var policy = getPolicy( arguments.context );

		if ( policy.min_length > 0 && arguments.password.len() < policy.min_length ) {
			return false;
		}

		if ( policy.min_uppercase > 0 ) {
			var upperCaseChars = ReReplace( arguments.password, "[^A-Z]", "", "all" );
			if ( upperCaseChars.len() < policy.min_uppercase ) {
				return false;
			}
		}

		if ( policy.min_numeric > 0 ) {
			var numericChars = ReReplace( arguments.password, "[^0-9]", "", "all" );
			if ( numericChars.len() < policy.min_numeric ) {
				return false;
			}
		}

		if ( policy.min_symbols > 0 ) {
			var specialChars = ReReplace( arguments.password, "[0-9A-Za-z]", "", "all" );
			if ( specialChars.len() < policy.min_symbols ) {
				return false;
			}
		}

		if ( policy.min_strength > 0 ) {
			var strength = _getPasswordStrengthAnalyzer().calculatePasswordStrength( arguments.password );

			if ( strength < policy.min_strength ) {
				 return false;
			}
		}

		return true;
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

	private any function _getPasswordStrengthAnalyzer() {
		return _passwordStrengthAnalyzer;
	}
	private void function _setPasswordStrengthAnalyzer( required any passwordStrengthAnalyzer ) {
		_passwordStrengthAnalyzer = arguments.passwordStrengthAnalyzer;
	}
}
