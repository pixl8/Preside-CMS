/**
 * Expression handler for "User is/is not logged in"
 *
 * @feature websiteUsers
 */
component {

	/**
	 * @expression true
	 *
	 */
	private boolean function webRequest( boolean _is=true ) {
		if ( arguments._is ) {
			return isLoggedIn();
		}

		return !isLoggedIn();
	}

}