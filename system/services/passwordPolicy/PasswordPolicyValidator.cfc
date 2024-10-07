/**
 * A class that provides validators for Preside's validation framework
 *
 * @singleton          true
 * @presideService     true
 * @validationProvider true
 * @feature            passwordPolicyManager
 */
component {

// CONSTRUCTOR
	/**
	 * @passwordPolicyService.inject delayedInjector:passwordPolicyService
	 */
	public any function init( required any passwordPolicyService ) {
		_setPasswordPolicyService( arguments.passwordPolicyService );

		return this;
	}

// VALIDATORS
	/**
	 * @validatorMessage cms:validation.meetsPasswordPolicy.default
	 *
	 */
	public boolean function meetsPasswordPolicy( required string fieldName, required string passwordPolicyContext, string value="" ) {
		if( !Len( arguments.value ) || !$isFeatureEnabled( "passwordPolicyManager") ) {
			return true;
		}

		return _getPasswordPolicyService().passwordMeetsPolicy( arguments.passwordPolicyContext, arguments.value );
	}

	public string function meetsPasswordPolicy_js() {
		return "function(){ return true; }";
	}

// GET SETS
	private any function _getPasswordPolicyService() {
		return _passwordPolicyService;
	}
	private void function _setPasswordPolicyService( required any passwordPolicyService ) {
		_passwordPolicyService = arguments.passwordPolicyService;
	}
}
