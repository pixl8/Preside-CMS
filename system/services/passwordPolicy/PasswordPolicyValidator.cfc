/**
 * A class that provides validators for PresideCMS's validation framework
 *
 * @singleton          true
 * @validationProvider true
 */
component {

// CONSTRUCTOR
	/**
	 * @passwordPolicyService.inject passwordPolicyService
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
		if( !Len( arguments.value ) ) {
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
