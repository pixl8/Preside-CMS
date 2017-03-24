/**
 * Expression handler for "User is/is not logged in"
 *
 * @feature websiteUsers
 * @expressionContexts webrequest
 * @expressionCategory website_user
 */
component {

	private boolean function evaluateExpression( boolean _is=true ) {
		if ( arguments._is ) {
			return isLoggedIn();
		}

		return !isLoggedIn();
	}

}