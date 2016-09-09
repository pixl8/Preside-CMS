/**
 * Expression handler for "User's email address matches pattern"
 *
 * @feature websiteUsers
 * @expressionContexts user
 */
component {

	property name="rulesEngineOperatorService" inject="rulesEngineOperatorService";

	/**
	 * @pattern.placeholder rules.expressions.UserEmailMatch.webrequest:field.pattern.placeholder
	 */
	private boolean function evaluateExpression(
		  required string  pattern
		,          string  _stringOperator = "eq"
		,          boolean _does           = true
	) {
		var details = payload.user ?: {};

		if ( details.isEmpty() ) {
			return false;
		}

		var matches = rulesEngineOperatorService.compareStrings(
			  leftHandSide  = ( details.email_address ?: "" )
			, operator      = arguments._stringOperator
			, rightHandSide = arguments.pattern
		);

		return _does ? matches : !matches;
	}

}