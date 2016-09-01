/**
 * Expression handler for "Day of the month is any of the following:"
 *
 */
component {

	/**
	 * @expression          true
	 * @months.fieldType    select
	 * @months.values       1,2,3,4,5,6,7,8,9,10,11,12
	 * @months.labelUriRoot cms:rulesEngine.months.
	 * @months.fieldLabel   cms:rulesEngine.months.label
	 */
	private boolean function global(
		  required string  months
		,          boolean _is = true
	) {
		var currentMonth = Month( Now() );
		var isMatched    = arguments.months.listToArray().find( currentMonth );

		return _is ? isMatched : !isMatched;
	}

}