/**
 * Expression handler for "Current page was embargoed within x days"
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
		,          string  _numericOperator="lt"
	) {
		var embargo = payload.page.embargo_date ?: "";

		if ( !IsDate( embargo ) ) {
			return false;
		}
		var daysFromEmbargo = DateDiff( "d", embargo, Now() );

		return daysFromEmbargo >=0 && rulesEngineOperatorService.compareNumbers( daysFromEmbargo, _numericOperator, arguments.days );
	}

}