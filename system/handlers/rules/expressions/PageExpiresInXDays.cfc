/**
 * Expression handler for "Current page expires in x days"
 *
 */
component {

	property name="rulesEngineOperatorService" inject="rulesEngineOperatorService";

	/**
	 * @expression true
	 * @expressionContexts webrequest,page
	 */
	private boolean function webRequest(
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