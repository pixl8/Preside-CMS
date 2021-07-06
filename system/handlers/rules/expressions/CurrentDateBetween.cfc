/**
 * Expression handler for "Current date is between"
 *
 * @expressionCategory currentdate
 */
component {

	/**
	 * @dateFrom.fieldType date
	 * @dateTo.fieldType   date
	 */
	private boolean function evaluateExpression(
		  required string  dateFrom
		, required string  dateTo
		,          boolean _is = true
	) {
		if ( !IsDate( arguments.dateFrom ) || !IsDate( arguments.dateTo ) ) {
			return false;
		}

		var isMatched = dateCompare( arguments.dateFrom, now(), "d" ) <= 0 && dateCompare( arguments.dateTo, now(), "d" ) >= 0;

		return _is ? isMatched : !isMatched;
	}

}