/**
 * Expression handler for "User is/is not logged in"
 *
 * @expressionContexts webrequest
 * @expressionCategory website_user
 * @feature            rulesEngine and websiteUsers
 */
component {

	private boolean function evaluateExpression( boolean _is=true ) {
		if ( arguments._is ) {
			return isLoggedIn();
		}

		return !isLoggedIn();
	}

}