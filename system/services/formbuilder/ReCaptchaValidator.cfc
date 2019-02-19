/**
 * @singleton          true
 * @validationProvider true
 * @presideService     true
 */
component {

// CONSTRUCTOR
	/**
	 * @recaptchaService.inject RecaptchaService
	 */
	public any function init( required any recaptchaService ) {
		_setRecaptchaService( arguments.recaptchaService );

		return this;
	}

// VALIDATORS
	/**
	 * @validatorMessage formbuilder:recaptcha.error.message
	 */
	public boolean function recaptcha() {
		var recaptchaResponse = $getRequestContext().getValue( name="g-recaptcha-response", defaultValue="" );

		if ( $getPresideSetting( "recaptcha", "secret_key" ).isEmpty() ) {
			return true;
		}

		return _getRecaptchaService().validate( recaptchaResponse );
	}


// GETTERS & SETTERS
	private any function _getRecaptchaService() {
		return _recaptchaService;
	}
	private void function _setRecaptchaService( required any recaptchaService ) {
		_recaptchaService = arguments.recaptchaService;
	}
}
