/**
 * Expression handler for "User has submitted a form builder form a number of times"
 *
 * @feature websiteUsers
 */
component {

	property name="websiteUserActionService" inject="websiteUserActionService";
	property name="rulesEngineOperatorService" inject="rulesEngineOperatorService";

	/**
	 * @expression         true
	 * @expressionContexts webrequest,user
	 * @fbform.fieldType   object
	 * @fbform.object      formbuilder_form
	 * @fbform.multiple    false
	 */
	private boolean function webRequest(
		  required string  fbform
		, required numeric times
		,          string  _numericOperator = "eq"
		,          boolean _has = true
	) {
		var userId = payload.user.id ?: "";
		var actionCount = websiteUserActionService.getActionCount(
			  type        = "formbuilder"
			, action      = "submitform"
			, userId      = userId
			, identifiers = [ fbform ]
		);

		var result = rulesEngineOperatorService.compareNumbers( actionCount, arguments._numericOperator, arguments.times );

		return _has ? result : !result;
	}

}