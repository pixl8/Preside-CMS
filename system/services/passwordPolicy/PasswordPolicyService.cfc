/**
 * A class that provides methods for dealing with all aspects of password policies
 *
 * @singleton      true
 * @presideService true
 * @feature        passwordPolicyManager
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

	public string function getStrengthNameForScore( required numeric score, boolean translate=false ) {
		var strengths = listStrengths();
		var strength  = strengths[ 1 ].name;

		for( var i=strengths.len(); i > 0; i-- ) {
			if ( arguments.score >= strengths[ i ].minValue ) {
				strength = strengths[ i ].name;
				break;
			}
		}

		if ( arguments.translate ) {
			return $translateResource( uri="cms:password.strength.#strength#.title", defaultValue=strength );
		}

		return strength
	}

	public array function listContexts() {
		var contexts = [ "cms" ];

		if ( $isFeatureEnabled( "websiteUsers" ) ) {
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

	public array function getDetailPolicyMessages(
		  required string context
		,          string password = ""
	) {
		var policy  = getPolicy( arguments.context );
		var message = [];

		if ( policy.min_strength > 0 ) {
			if ( !isEmpty( arguments.password ) ) {
				var strength = _getPasswordStrengthAnalyzer().calculatePasswordStrength( arguments.password );

				if ( strength < policy.min_strength ) {
					message.append( $translateResource( uri="cms:passwordpolicy.strengthRequired.message", data=[ getStrengthNameForScore( policy.min_strength, true ) ] ) );
				}
			} else {
				message.append( $translateResource( uri="cms:passwordpolicy.strengthRequired.message", data=[ getStrengthNameForScore( policy.min_strength, true ) ] ) );
			}
		}

		if ( policy.min_length > 0 ) {
			if ( !isEmpty( arguments.password ) ) {
				if ( arguments.password.len() < policy.min_length ) {
					message.append( $translateResource( uri="cms:passwordpolicy.lengthRequired.message", data=[ policy.min_length ] ) );
				}
			} else {
				message.append( $translateResource( uri="cms:passwordpolicy.lengthRequired.message", data=[ policy.min_length ] ) );
			}
		}

		if ( policy.min_uppercase > 0 ) {
			if ( !isEmpty( arguments.password ) ) {
				var upperCaseChars = ReReplace( arguments.password, "[^A-Z]", "", "all" );
				if ( upperCaseChars.len() < policy.min_uppercase ) {
					message.append( $translateResource( uri="cms:passwordpolicy.uppercaseLengthRequired.message", data=[ policy.min_uppercase ] ) );
				}
			} else {
				message.append( $translateResource( uri="cms:passwordpolicy.uppercaseLengthRequired.message", data=[ policy.min_uppercase ] ) );
			}
		}

		if ( policy.min_numeric > 0 ) {
			if ( !isEmpty( arguments.password ) ) {
				var numericChars = ReReplace( arguments.password, "[^0-9]", "", "all" );
				if ( numericChars.len() < policy.min_numeric ) {
					message.append( $translateResource( uri="cms:passwordpolicy.numberLengthRequired.message", data=[ policy.min_numeric ] ) );
				}
			} else {
				message.append( $translateResource( uri="cms:passwordpolicy.numberLengthRequired.message", data=[ policy.min_numeric ] ) );
			}
		}

		if ( policy.min_symbols > 0 ) {
			if ( !isEmpty( arguments.password ) ) {
				var specialChars = ReReplace( arguments.password, "[0-9A-Za-z]", "", "all" );
				if ( specialChars.len() < policy.min_symbols ) {
					message.append( $translateResource( uri="cms:passwordpolicy.specialCharactersLengthRequired.message", data=[ policy.min_symbols ] ) );
				}
			} else {
				message.append( $translateResource( uri="cms:passwordpolicy.specialCharactersLengthRequired.message", data=[ policy.min_symbols ] ) );
			}
		}

		return message;
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
