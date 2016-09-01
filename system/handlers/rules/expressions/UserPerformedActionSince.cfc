/**
 * Expression handler for "User has performed action recently "
 *
 * @feature websiteUsers
 */
component {

	property name="websiteUserActionService"   inject="websiteUserActionService";

	/**
	 * @expression         true
	 * @expressionContexts webrequest,user
	 * @action.fieldType   websiteUserAction
	 * @action.multiple    false
	 */
	private boolean function webRequest(
		  required string  action
		, required date    since
		,          boolean _has = true
	) {
		if ( ListLen( action, "." ) != 2 ) {
			return false;
		}

		var result = websiteUserActionService.hasPerformedAction(
			  type   = ListFirst( action, "." )
			, action = ListLast( action, "." )
			, userId = payload.user.id ?: ""
			, since  = since
		);

		return _has ? result : !result;
	}

}