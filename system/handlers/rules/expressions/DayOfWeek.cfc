/**
 * Expression handler for "Day of the week is any of the following:"
 *
 */
component {

	/**
	 * @days.fieldType    select
	 * @days.values       2,3,4,5,6,7,1
	 * @days.labelUriRoot cms:rulesEngine.daysOfWeek.
	 * @days.fieldLabel   cms:rulesEngine.daysOfWeek.label
	 */
	private boolean function evaluateExpression(
		  required string  days
		,          boolean _is = true
	) {
		var currentDayOfWeek = DayOfWeek( Now() );
		var isMatched        = arguments.days.listToArray().find( currentDayOfWeek );

		return _is ? isMatched : !isMatched;
	}

}