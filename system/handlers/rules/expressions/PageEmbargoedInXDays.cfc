/**
 * Expression handler for "Current page was embargoed within x days"
 *
 * @expressionContexts page
 */
component {

	property name="rulesEngineOperatorService" inject="rulesEngineOperatorService";

	private boolean function evaluateExpression(
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