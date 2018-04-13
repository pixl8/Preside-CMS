/**
 * Expression handler for "User has/does not have any benefits"
 *
 * @feature websiteBenefits
 * @expressionContexts user
 * @expressionCategory website_user
 */
component {

	property name="websitePermissionService" inject="websitePermissionService";

	private boolean function evaluateExpression( boolean _possesses=true ) {
		var hasBenefits = false;

		if ( Len( Trim( payload.user.id ?: "" )) ) {
			var userBenefits = websitePermissionService.listUserBenefits( payload.user.id );

			hasBenefits  = userBenefits.len();
		}

		return _possesses ? hasBenefits : !hasBenefits;
	}

}