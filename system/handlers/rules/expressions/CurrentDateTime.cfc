/**
 * Expression handler for "Current date/time"
 *
 * @expressionCategory currentdate
 */
component {

	private boolean function evaluateExpression(
		struct _time = {}
	) {
		var _now = Now();

		if ( IsDate( _time.from ?: "" ) ) {
			if ( DateCompare( _now, _time.from ) == -1 ) {
				return false;
			}
		}

		if ( IsDate( _time.to ?: "" ) ) {
			if ( DateCompare( _now, _time.to ) == 1 ) {
				return false;
			}
		}

		return true;
	}

}