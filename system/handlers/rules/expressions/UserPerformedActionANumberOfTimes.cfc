/**
 * Expression handler for "User has performed action a number of times "
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
		, required numeric times
		,          boolean _has            = true
		,          string _numericOperator = "eq"
		,          struct _pastTime
	) {
		if ( ListLen( action, "." ) != 2 ) {
			return false;
		}

		var actionCount = websiteUserActionService.getActionCount(
			  type   = ListFirst( action, "." )
			, action = ListLast( action, "." )
			, userId = payload.user.id ?: ""
			, dateFrom = _pastTime.from ?: ""
			, dateTo   = _pastTime.to   ?: ""
		);
		var result = rulesEngineOperatorService.compareNumbers( actionCount, arguments._numericOperator, arguments.times );

		return _has ? result : !result;
	}

}