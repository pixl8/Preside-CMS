/**
 * Provides methods for converting a saved time period into a date range
 *
 * @autodoc
 * @singleton
 *
 */
component displayName="RulesEngine Time Period Service" {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API
	/**
	 * Converts a json representation of a time period into a
	 * struct with dateFrom and dateTo keys. If no time period
	 * detected, the struct will be empty.
	 *
	 * @autodoc
	 * @timePeriodJson.hint JSON string representing the time period
	 */
	public struct function convertTimePeriodToDateRange( required string timePeriodJson ) {
		try {
			var timePeriod = DeserializeJson( timePeriodJson );
		} catch( any e ){
			return {};
		};

		switch( timePeriod.type ?: "" ) {
			case "between":
				if ( IsDate( timePeriod.date1 ?: "" ) && IsDate( timePeriod.date2 ?: "" ) ) {
					return { from=timePeriod.date1, to=timePeriod.date2 };
				}
			break;
			case "since":
				if ( IsDate( timePeriod.date1 ?: "" ) ) {
					return { from=timePeriod.date1, to=_getCurrentDateTime() };
				}
			break;
			case "until":
				if ( IsDate( timePeriod.date1 ?: "" ) ) {
					return { from=_getCurrentDateTime(), to=timePeriod.date1 };
				}
			break;
			case "before":
				if ( IsDate( timePeriod.date1 ?: "" ) ) {
					return { to=timePeriod.date1 };
				}
			break;
			case "after":
				if ( IsDate( timePeriod.date1 ?: "" ) ) {
					return { from=timePeriod.date1 };
				}
			break;
			case "recent":
				try {
					var fromDate = DateAdd( ( timePeriod.unit ?: "" ), -( timePeriod.measure ?: "" ), _getCurrentDateTime() );
				} catch( any e ) {
					return {};
				}

				return {
					  from = CreateDate( Year( fromDate ), Month( fromDate ), Day( fromDate ) )
					, to   = _getCurrentDateTime()
				};
			break;

			case "upcoming":
				try {
					var toDate = DateAdd( ( timePeriod.unit ?: "" ), ( timePeriod.measure ?: "" ), _getCurrentDateTime() );
				} catch( any e ) {
					return {};
				}

				return {
					  to   = CreateDate( Year( toDate ), Month( toDate ), Day( toDate ) )
					, from = _getCurrentDateTime()
				};
			break;

			case "future":
			return { from=_getCurrentDateTime() };

			case "futureplus":
				try {
					return { from = DateAdd( ( timePeriod.unit ?: "" ), ( timePeriod.measure ?: "" ), _getCurrentDateTime() ) };
				} catch( any e ) {
					return {};
				}
			break;

			case "past":
			return { to=_getCurrentDateTime() };

			case "pastminus":
				try {
					return { to = DateAdd( ( timePeriod.unit ?: "" ), 0-( timePeriod.measure ?: "" ), _getCurrentDateTime() ) };
				} catch( any e ) {
					return {};
				}
			break;

			case "yesterday":
				var dateFrom = DateAdd( "d", -1, _getCurrentDateTime() );
					dateFrom.setHour( "0" );
					dateFrom.setMinute( "0" );
					dateFrom.setSecond( "0" );
				var dateTo = Duplicate( dateFrom );
					dateTo.setHour( "23" );
					dateTo.setMinute( "59" );
					dateTo.setSecond( "59" );

				return {
					  to   = dateTo
					, from = dateFrom
				};
			break;

			case "today":
				var dateFrom = _getCurrentDateTime();
					dateFrom.setHour( "0" );
					dateFrom.setMinute( "0" );
					dateFrom.setSecond( "0" );
				var dateTo = Duplicate( dateFrom );
					dateTo.setHour( "23" );
					dateTo.setMinute( "59" );
					dateTo.setSecond( "59" );

				return {
					  to   = dateTo
					, from = dateFrom
				};
			break;

			case "tomorrow":
				var dateFrom = DateAdd( "d", 1, _getCurrentDateTime() );
					dateFrom.setHour( "0" );
					dateFrom.setMinute( "0" );
					dateFrom.setSecond( "0" );
				var dateTo = Duplicate( dateFrom );
					dateTo.setHour( "23" );
					dateTo.setMinute( "59" );
					dateTo.setSecond( "59" );

				return {
					  to   = dateTo
					, from = dateFrom
				};
			break;

			case "lastweek":
				var offsetDay = DayOfWeek(_getCurrentDateTime());
				var dateFrom  = DateAdd( "d", 1 - offsetDay - 7, _getCurrentDateTime() );
					dateFrom.setHour( "0" );
					dateFrom.setMinute( "0" );
					dateFrom.setSecond( "0" );
				var dateTo = DateAdd( "d", 6, dateFrom );
					dateTo.setHour( "23" );
					dateTo.setMinute( "59" );
					dateTo.setSecond( "59" );

				return {
					  to   = dateTo
					, from = dateFrom
				};
			break;

			case "thisweek":
				var offsetDay = DayOfWeek(_getCurrentDateTime());
				var dateFrom  = DateAdd( "d", 1 - offsetDay, _getCurrentDateTime() );
					dateFrom.setHour( "0" );
					dateFrom.setMinute( "0" );
					dateFrom.setSecond( "0" );
				var dateTo = DateAdd( "d", 6, dateFrom );
					dateTo.setHour( "23" );
					dateTo.setMinute( "59" );
					dateTo.setSecond( "59" );

				return {
					  to   = dateTo
					, from = dateFrom
				};
			break;

			case "nextweek":
				var offsetDay = DayOfWeek(_getCurrentDateTime());
				var dateFrom  = DateAdd( "d", 1 - offsetDay + 7, _getCurrentDateTime() );
					dateFrom.setHour( "0" );
					dateFrom.setMinute( "0" );
					dateFrom.setSecond( "0" );
				var dateTo = DateAdd( "d", 6, dateFrom );
					dateTo.setHour( "23" );
					dateTo.setMinute( "59" );
					dateTo.setSecond( "59" );

				return {
					  to   = dateTo
					, from = dateFrom
				};
			break;

			case "lastmonth":
				var firstOfThisMonth = CreateDateTime(year(_getCurrentDateTime()), month(_getCurrentDateTime()), 1, 0, 0, 0);
				var firstOfLastMonth = DateAdd( "m", -1, firstOfThisMonth );
				var endOfLastMonth   = DateAdd( "d", -1, firstOfThisMonth );
					endOfLastMonth.setHour( "23" );
					endOfLastMonth.setMinute( "59" );
					endOfLastMonth.setSecond( "59" );
				return {
					  to   = endOfLastMonth
					, from = firstOfLastMonth
				};
			break;

			case "thismonth":
				var firstOfThisMonth = CreateDateTime(year(_getCurrentDateTime()), month(_getCurrentDateTime()), 1, 0, 0, 0);
				var firstOfNextMonth = DateAdd( "m", 1, firstOfThisMonth );
				var endOfThisMonth   = DateAdd( "d", -1, firstOfNextMonth );
					endOfThisMonth.setHour( "23" );
					endOfThisMonth.setMinute( "59" );
					endOfThisMonth.setSecond( "59" );
				return {
					  to   = endOfThisMonth
					, from = firstOfThisMonth
				};
			break;

			case "nextmonth":
				var firstOfNextMonth   = CreateDateTime(year(_getCurrentDateTime()), month(_getCurrentDateTime())+1, 1, 0, 0, 0);
				var firstOfNext2Months = DateAdd( "m", 1, firstOfNextMonth );
				var endOfNextMonth     = DateAdd( "d", -1, firstOfNext2Months );
					endOfNextMonth.setHour( "23" );
					endOfNextMonth.setMinute( "59" );
					endOfNextMonth.setSecond( "59" );
				return {
					  to   = endOfNextMonth
					, from = firstOfNextMonth
				};
			break;
		}

		return {};
	}


// private helpers
	private date function _getCurrentDateTime() {
		return Now();
	}

}