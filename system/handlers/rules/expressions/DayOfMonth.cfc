/**
 * Expression handler for "Day of the month is any of the following:"
 *
 */
component {

	/**
	 * @days.fieldType    select
	 * @days.values       1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31
	 * @days.fieldLabel   cms:rulesEngine.daysOfMonth.label
	 */
	private boolean function evaluateExpression(
		  required string  days
		,          boolean _is = true
	) {
		var currentDayOfMonth = Day( Now() );
		var isMatched         = arguments.days.listToArray().find( currentDayOfMonth );

		return _is ? isMatched : !isMatched;
	}

}