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

		var currentDateTime = _getCurrentDateTime();

		switch( timePeriod.type ?: "" ) {
			case "between":
				if ( IsDate( timePeriod.date1 ?: "" ) && IsDate( timePeriod.date2 ?: "" ) ) {
					return { from=timePeriod.date1, to=timePeriod.date2 };
				}
			break;
			case "since":
				if ( IsDate( timePeriod.date1 ?: "" ) ) {
					return { from=timePeriod.date1, to=currentDateTime };
				}
			break;
			case "until":
				if ( IsDate( timePeriod.date1 ?: "" ) ) {
					return { from=currentDateTime, to=timePeriod.date1 };
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
					var fromDate = DateAdd( ( timePeriod.unit ?: "" ), -Val( timePeriod.measure ?: "" ), currentDateTime );
				} catch( any e ) {
					return {};
				}

				return {
					  from = fromDate
					, to   = currentDateTime
				};
			break;

			case "upcoming":
				try {
					var toDate = DateAdd( ( timePeriod.unit ?: "" ), Val( timePeriod.measure ?: "" ), currentDateTime );
				} catch( any e ) {
					return {};
				}

				return {
					  to   = toDate
					, from = currentDateTime
				};
			break;

			case "future":
				return { from=currentDateTime };
			break;

			case "futureplus":
				try {
					return { from = DateAdd( ( timePeriod.unit ?: "" ), Val( timePeriod.measure ?: "" ), currentDateTime ) };
				} catch( any e ) {
					return {};
				}
			break;

			case "past":
				return { to=currentDateTime };
			break;

			case "pastminus":
				try {
					return { to = DateAdd( ( timePeriod.unit ?: "" ), 0-Val( timePeriod.measure ?: "" ), currentDateTime ) };
				} catch( any e ) {
					return {};
				}
			break;

			case "yesterday":
				var dateFrom        = DateAdd( "d", -1, CreateDateTime( Year( currentDateTime ), Month( currentDateTime ), Day( currentDateTime ) ) );
				var dateTo          = CreateDateTime( Year( dateFrom ), Month( dateFrom ), Day( dateFrom ), 23, 59, 59 );

				return {
					  to   = dateTo
					, from = dateFrom
				};
			break;

			case "today":
				var dateFrom        = CreateDateTime( Year( currentDateTime ), Month( currentDateTime ), Day( currentDateTime ) );
				var dateTo          = CreateDateTime( Year( dateFrom )       , Month( dateFrom )       , Day( dateFrom ), 23, 59, 59 );

				return {
					  to   = dateTo
					, from = dateFrom
				};
			break;

			case "tomorrow":
				var dateFrom        = DateAdd( "d", 1, CreateDateTime( Year( currentDateTime ), Month( currentDateTime ), Day( currentDateTime ) ) );
				var dateTo          = CreateDateTime( Year( dateFrom ), Month( dateFrom ), Day( dateFrom ), 23, 59, 59 );

				return {
					  to   = dateTo
					, from = dateFrom
				};
			break;

			case "lastweek":
				var offsetDay       = DayOfWeek( currentDateTime );
				var dateFrom        = DateAdd( "d", 1 - offsetDay - 7, CreateDateTime( Year( currentDateTime ), Month( currentDateTime ), Day( currentDateTime ) ) );
				var dateTo          = DateAdd( "d", 6                , CreateDateTime( Year( dateFrom )       , Month( dateFrom )       , Day( dateFrom ), 23, 59, 59 ) );

				return {
					  to   = dateTo
					, from = dateFrom
				};
			break;

			case "thisweek":
				var offsetDay       = DayOfWeek( currentDateTime );
				var dateFrom        = DateAdd( "d", 1 - offsetDay, CreateDateTime( Year( currentDateTime ), Month( currentDateTime ), Day( currentDateTime ) ) );
				var dateTo          = DateAdd( "d", 6            , CreateDateTime( Year( dateFrom )       , Month( dateFrom )       , Day( dateFrom ), 23, 59, 59 ) );

				return {
					  to   = dateTo
					, from = dateFrom
				};
			break;

			case "nextweek":
				var offsetDay       = DayOfWeek( currentDateTime );
				var dateFrom        = DateAdd( "d", 1 - offsetDay + 7, CreateDateTime( Year( currentDateTime ), Month( currentDateTime ), Day( currentDateTime ) ) );
				var dateTo          = DateAdd( "d", 6                , CreateDateTime( Year( dateFrom )       , Month( dateFrom )       , Day( dateFrom ), 23, 59, 59 ) );

				return {
					  to   = dateTo
					, from = dateFrom
				};
			break;

			case "lastmonth":
				var firstOfThisMonth = CreateDateTime( Year( currentDateTime ), Month( currentDateTime ), 1, 0, 0, 0 );
				var firstOfLastMonth = DateAdd( "m", -1, firstOfThisMonth );
				var endOfLastMonth   = DateAdd( "s", -1, firstOfThisMonth );

				return {
					  to   = endOfLastMonth
					, from = firstOfLastMonth
				};
			break;

			case "thismonth":
				var firstOfThisMonth = CreateDateTime( Year( currentDateTime ), Month( currentDateTime ), 1, 0, 0, 0 );
				var firstOfNextMonth = DateAdd( "m", 1, firstOfThisMonth );
				var endOfThisMonth   = DateAdd( "s", -1, firstOfNextMonth );

				return {
					  to   = endOfThisMonth
					, from = firstOfThisMonth
				};
			break;

			case "nextmonth":
				var nextMonthDate      = DateAdd( "m", 1, currentDateTime );
				var firstOfNextMonth   = CreateDateTime( Year( nextMonthDate ), Month( nextMonthDate ), 1, 0, 0, 0);
				var firstOfNext2Months = DateAdd( "m", 1, firstOfNextMonth );
				var endOfNextMonth     = DateAdd( "s", -1, firstOfNext2Months );

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