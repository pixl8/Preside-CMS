/**
 * Expression handler for "User's email address matches pattern"
 *
 * @feature websiteUsers
 */
component {

	property name="rulesEngineOperatorService" inject="rulesEngineOperatorService";

	/**
	 * @expression         true
	 * @expressionContexts webrequest,user
	 * @action.fieldType   websiteUserAction
	 * @action.multiple    false
	 * @days.fieldLabel    rules.expressions.UserLastPerformedAction.webrequest:field.days.config.label
	 */
	private boolean function webRequest(
		  required string  action
		, required numeric days
		,          string  _numericOperator = "gt"
	) {
		return true;
	}

}