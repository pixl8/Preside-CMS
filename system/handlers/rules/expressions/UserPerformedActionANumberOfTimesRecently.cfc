/**
 * Expression handler for "User has performed action a number of times recently"
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
	 * @days.fieldLabel    rules.expressions.UserPerformedActionANumberOfTimesRecently.webrequest:field.days.config.label
	 */
	private boolean function webRequest(
		  required string  action
		, required numeric times
		, required numeric days
		,          boolean _has            = true
		,          string _numericOperator = "eq"
	) {
		if ( ListLen( action, "." ) != 2 ) {
			return false;
		}

		var actionCount = websiteUserActionService.getActionCount(
			  type   = ListFirst( action, "." )
			, action = ListLast( action, "." )
			, userId = payload.user.id ?: ""
			, since  = DateAdd( "d", -days, Now() )
		);
		var result = rulesEngineOperatorService.compareNumbers( actionCount, arguments._numericOperator, arguments.times );

		return _has ? result : !result;
	}

}