/**
 * Expression handler for "User has visited a page a number of times"
 *
 * @feature websiteUsers
 */
component {

	property name="websiteUserActionService" inject="websiteUserActionService";
	property name="rulesEngineOperatorService" inject="rulesEngineOperatorService";

	/**
	 * @expression         true
	 * @expressionContexts webrequest,user
	 * @page.fieldType     page
	 * @page.multiple      false
	 * @days.fieldLabel    rules.expressions.UserPerformedActionRecently.webrequest:field.days.config.label
	 */
	private boolean function webRequest(
		  required string  page
		, required numeric times
		, required numeric days
		,          string  _numericOperator = "eq"
		,          boolean _has = true
	) {
		var userId = payload.user.id ?: "";
		var actionCount = websiteUserActionService.getActionCount(
			  type        = "request"
			, action      = "pagevisit"
			, userId      = userId
			, identifiers = [ page ]
			, since       = DateAdd( "d", -days, Now() )
		);

		var result = rulesEngineOperatorService.compareNumbers( actionCount, arguments._numericOperator, arguments.times );

		return _has ? result : !result;
	}

}