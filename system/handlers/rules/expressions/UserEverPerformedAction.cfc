/**
 * Expression handler for "User has ever performed action"
 *
 * @feature websiteUsers
 */
component {

	property name="rulesEngineOperatorService" inject="rulesEngineOperatorService";
	property name="websiteUserActionService"   inject="websiteUserActionService";

	/**
	 * @expression         true
	 * @expressionContexts webrequest,user
	 * @action.fieldType   websiteUserAction
	 * @action.multiple    false
	 */
	private boolean function webRequest(
		  required string  action
		,          boolean _ever = true
	) {
		if ( ListLen( action, "." ) != 2 ) {
			return false;
		}

		var result = websiteUserActionService.hasPerformedAction(
			  type   = ListFirst( action, "." )
			, action = ListLast( action, "." )
			, userId = payload.user.id ?: ""
		);

		return _ever ? result : !result;
	}

}