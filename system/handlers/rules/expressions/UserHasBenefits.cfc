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
		if ( !Len( Trim( payload.user.id ?: "" ) ) ) {
			return false;
		}
		if ( !arguments.benefits.len() ) {
			return false;
		}

		for( var benefit in arguments.benefits.listToArray() ) {
			var userHasBenefit = websitePermissionService.userHasBenefit( payload.user.id, benefit );

			if ( _posesses ) {
				if ( _all && !userHasBenefit ) {
					return false;
				} else if ( !_all && userHasBenefit ) {
					return true;
				}
			} else {
				if ( _all && userHasBenefit ) {
					return false;
				} else if ( !_all && !userHasBenefit ) {
					return true;
				}
			}
		}

		return _posesses ? _all : !_all;
	}

}