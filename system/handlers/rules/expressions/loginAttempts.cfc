/**
 * Expression handler for "login attempts:"
 *
 */
component {

	property name="websiteLoginService" inject="websiteLoginService";

	/**
	 * @lockoutMessage.fieldType       richeditor
	 */
	private boolean function evaluateExpression(
		  required numeric loginAttempts
		, required numeric lockoutTime
		, required string  lockoutMessage
		,          boolean _is            = true
	) {
		var userDetails = payload.user ?: {};

		if ( !val( arguments.loginAttempts ) || !val( arguments.lockoutTime ) || !userDetails.count() || !val( userDetails.invalid_login_attempts ) ) {
			return false;
		}

		if( !val( userDetails.lockout_permanently ) && val( arguments.lockoutTime ) < dateDiff( "n", userDetails.invalid_login_at, now() ) ) {
			websiteLoginService.recordLoginAttempts( userId=userDetails.id, invalid_login_attempts=0 );
		}

		if( val( userDetails.lockout_permanently ) || val( userDetails.invalid_login_attempts ) >= val( arguments.loginAttempts ) && val( arguments.lockoutTime ) >= dateDiff( "n", userDetails.invalid_login_at, now() ) ) {

			if( arguments._is ) {
				websiteLoginService.recordLoginAttempts( userId=userDetails.id, invalid_login_attempts=userDetails.invalid_login_attempts, lockout_permanently=1 );
			}

			return true;
		}

		return false;
	}

}