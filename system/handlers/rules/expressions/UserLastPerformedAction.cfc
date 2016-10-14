/**
 * Expression handler for "User's has performed some action within the last x days"
 *
 * @feature websiteUsers
 * @expressionContexts user
 */
component {

	property name="websiteUserActionService"   inject="websiteUserActionService";

	/**
	 * @action.fieldType   websiteUserAction
	 * @action.multiple    false
	 */
	private boolean function evaluateExpression(
		  required string  action
		,          struct  _pastTime
	) {
		if ( ListLen( action, "." ) != 2 ) {
			return false;
		}

		var lastPerformedDate = websiteUserActionService.getLastPerformedDate(
			  type   = ListFirst( action, "." )
			, action = ListLast( action, "." )
			, userId = payload.user.id ?: ""
		);

		if ( !IsDate( lastPerformedDate ) ) {
			return false;
		}

		if ( IsDate( _pastTime.from ?: "" ) && lastPerformedDate < _pastTime.from ) {
			return false;
		}
		if ( IsDate( _pastTime.to ?: "" ) && lastPerformedDate > _pastTime.to ) {
			return false;
		}

		return true;
	}

}