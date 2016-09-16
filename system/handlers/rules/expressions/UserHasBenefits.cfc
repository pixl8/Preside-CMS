/**
 * Expression handler for "User has/has not all/any of the following benefits: {benefit list}"
 *
 * @feature websiteBenefits
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
		if ( !Len( Trim( payload.user.id ?: "" ) ) ) {
			return false;
		}

		if ( !arguments.benefits.len() ) {
			return false;
		}

		var benefitsToMatch  = arguments.benefits.trim().listToArray();
		var userBenefits     = websitePermissionService.listUserBenefits( payload.user.id );
		var matchingBenefits = userBenefits.filter( function( benefit ){
			return benefits.findNoCase( benefit );
		} );


		if ( _all ) {
			hasBenefits = _posesses ? ( matchingBenefits.len() == benefitsToMatch.len() ) : matchingBenefits.len();
		} else {
			hasBenefits = _posesses ? matchingBenefits.len() : ( matchingBenefits.len() == benefitsToMatch.len() );
		}

		return _posesses ? hasBenefits : !hasBenefits;
	}

}