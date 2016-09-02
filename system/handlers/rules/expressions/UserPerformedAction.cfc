/**
 * Expression handler for "User has performed some action in some time frame"
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
		,          boolean _has = true
		,          struct  _pastTime
	) {
		if ( ListLen( action, "." ) != 2 ) {
			return false;
		}

		var result = websiteUserActionService.hasPerformedAction(
			  type     = ListFirst( action, "." )
			, action   = ListLast( action, "." )
			, userId   = payload.user.id ?: ""
			, dateFrom = _pastTime.from ?: ""
			, dateTo   = _pastTime.to   ?: ""
		);

		return _has ? result : !result;
	}

}