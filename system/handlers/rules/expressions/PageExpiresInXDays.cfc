/**
 * Expression handler for "Current page expires in x days"
 *
 * @expressionContexts page
 */
component {

	property name="rulesEngineOperatorService" inject="rulesEngineOperatorService";

	private boolean function evaluateExpression(
		  required numeric days
		,          string  _periodOperator="lte"
	) {
		var expiry = payload.page.expiry_date ?: "";

		if ( !IsDate( expiry ) ) {
			return false;
		}
		var daysToExpiry = DateDiff( "d", Now(), expiry );

		return daysToExpiry >=0 && rulesEngineOperatorService.compareNumbers( daysToExpiry, _periodOperator, arguments.days );
	}

}