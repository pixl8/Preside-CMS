/**
 * Expression handler for "User has/does not have any benefits"
 *
 */
component {

	property name="websitePermissionService" inject="websitePermissionService";

	/**
	 * @expression         true
	 * @benefits.fieldType object
	 * @benefits.object    website_benefit
	 */
	private boolean function webRequest(
		boolean _has=true
	) {
		var hasBenefits = false;

		if ( isLoggedIn() ) {
			var userId       = getLoggedInUserId();
			var userBenefits = websitePermissionService.listUserBenefits( userId );

			hasBenefits  = userBenefits.len();
		}

		return _has ? hasBenefits : !hasBenefits;
	}

}