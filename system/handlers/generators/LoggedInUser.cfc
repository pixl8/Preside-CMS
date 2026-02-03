/**
 * Gets the id of the Logged in user
 *
 * @feature websiteUsers
 */
component {
	property name="loginService"                     inject="loginService";

	private string function loggedInUserId( event, rc, prc, args={} ) {
		var userId = loginService.getLoggedInUserId()
		return userId;
	}
}