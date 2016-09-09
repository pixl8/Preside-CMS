/**
 * Expression handler for "User has/has not all/any of the following benefits: {benefit list}"
 *
 * @feature websiteUsers
 * @expressionContexts user
 */
component {

	property name="websitePermissionService" inject="websitePermissionService";

	/**
	 * @benefits.fieldType object
	 * @benefits.object    website_benefit
	 */
	private boolean function evaluateExpression(
		  required string  benefits
		,          boolean _posesses=true
		,          boolean _all=true
	) {
		var hasBenefits = !arguments.benefits.len();

		if ( !hasBenefits ) {
			if ( Len( Trim( payload.user.id ?: "" ) ) ) {
				var userBenefits     = websitePermissionService.listUserBenefits( payload.user.id );
				var matchingBenefits = userBenefits.filter( function( benefit ){
					return benefits.findNoCase( benefit );
				} );

				if ( _all ) {
					hasBenefits = _posesses ? ( matchingBenefits.len() == benefits.len() ) : matchingBenefits.len();
				} else {
					hasBenefits = _posesses ? matchingBenefits.len() : ( matchingBenefits.len() == benefits.len() );
				}
			}
		}

		return _posesses ? hasBenefits : !hasBenefits;
	}

}