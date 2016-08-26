/**
 * Expression handler for "User has/has not all/any of the following benefits: {benefit list}"
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
		  required string  benefits
		,          boolean _has=true
		,          boolean _all=true
	) {
		var hasBenefits = !arguments.benefits.len();

		if ( !hasBenefits ) {
			if ( isLoggedIn() ) {
				var userId       = getLoggedInUserId();
				var userBenefits = websitePermissionService.listUserBenefits( userId );
				var matchingBenefits = userBenefits.filter( function( benefit ){
					return benefits.findNoCase( benefit );
				} );

				if ( _all ) {
					hasBenefits = matchingBenefits.len() == benefits.len();
				} else {
					hasBenefits = matchingBenefits.len();
				}
			}
		}

		return _has ? hasBenefits : !hasBenefits;
	}

}