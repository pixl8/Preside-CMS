/**
 * Expression handler for "Current page expires in x days"
 *
 */
component {

	property name="rulesEngineOperatorService" inject="rulesEngineOperatorService";

	/**
	 * @expression true
	 */
	private boolean function webRequest(
		  required numeric days
		,          string  _periodOperator="lte"
	) {
		var expiry = event.getPageProperty( "expiry_date" );

		if ( !IsDate( expiry ) ) {
			return false;
		}
		var daysToExpiry = DateDiff( "d", expiry, Now() );

		return daysToExpiry >=0 && rulesEngineOperatorService.compareNumbers( daysToExpiry, _periodOperator, arguments.days );
	}

}