/**
 * Expression handler for "User's email address matches pattern"
 *
 * @feature websiteUsers
 */
component {

	property name="rulesEngineOperatorService" inject="rulesEngineOperatorService";

	/**
	 * @expression true
	 * @expressionContexts webrequest,user
	 * @pattern.placeholder rules.expressions.UserEmailMatch.webrequest:field.pattern.placeholder
	 */
	private boolean function webRequest(
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