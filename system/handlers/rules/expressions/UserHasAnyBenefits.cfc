/**
 * Expression handler for "User has/does not have any benefits"
 *
 */
component {

	property name="websitePermissionService" inject="websitePermissionService";

	/**
	 * @expression         true
	 * @expressionContexts webrequest,user
	 * @benefits.fieldType object
	 * @benefits.object    website_benefit
	 */
	private boolean function webRequest(
		boolean _has=true
	) {
		var hasBenefits = false;

		if ( Len( Trim( payload.user.id ?: "" )) ) {
			var userBenefits = websitePermissionService.listUserBenefits( payload.user.id );

			hasBenefits  = userBenefits.len();
		}

		return _has ? hasBenefits : !hasBenefits;
	}

}