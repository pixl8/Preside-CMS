/**
 * Provides methods for converting a saved time period into a date range
 *
 * @autodoc   true
 * @singleton true
 * @feature   rulesEngine
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
			case "equal":
				if ( IsDate( timePeriod.date1 ?: "" ) ) {
					try {
						var fromDate = CreateDate( Year( timePeriod.date1 ), Month( timePeriod.date1 ), Day( timePeriod.date1 ) );

						return {
							  from = fromDate
							, to   = DateAdd( "s", 86399, fromDate )
						};
					} catch( any e ) {
						return {};
					}
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

			case "futureequal":
				try {
					var futureDate = DateAdd( "d", ( timePeriod.measure ?: "" ), _getCurrentDateTime() );
					var fromDate   = CreateDate( Year( futureDate ), Month( futureDate ), Day( futureDate ) );

					return {
						  from = fromDate
						, to   = DateAdd( "s", 86399, fromDate )
					};
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

			case "pastequal":
				try {
					var pastDate = DateAdd( "d", 0-( timePeriod.measure ?: "" ), _getCurrentDateTime() );
					var fromDate = CreateDate( Year( pastDate ), Month( pastDate ), Day( pastDate ) );

					return {
						  from = fromDate
						, to   = DateAdd( "s", 86399, fromDate )
					};
				} catch( any e ) {
					return {};
				}
			break;

			case "yesterday":
				var currentDateTime = _getCurrentDateTime();
				var dateFrom        = DateAdd( "d", -1, CreateDateTime( Year( currentDateTime ), Month( currentDateTime ), Day( currentDateTime ) ) );
				var dateTo          = CreateDateTime( Year( dateFrom ), Month( dateFrom ), Day( dateFrom ), 23, 59, 59 );

				return {
					  to   = dateTo
					, from = dateFrom
				};
			break;

			case "today":
				var currentDateTime = _getCurrentDateTime();
				var dateFrom        = CreateDateTime( Year( currentDateTime ), Month( currentDateTime ), Day( currentDateTime ) );
				var dateTo          = CreateDateTime( Year( dateFrom )       , Month( dateFrom )       , Day( dateFrom ), 23, 59, 59 );

				return {
					  to   = dateTo
					, from = dateFrom
				};
			break;

			case "tomorrow":
				var currentDateTime = _getCurrentDateTime();
				var dateFrom        = DateAdd( "d", 1, CreateDateTime( Year( currentDateTime ), Month( currentDateTime ), Day( currentDateTime ) ) );
				var dateTo          = CreateDateTime( Year( dateFrom ), Month( dateFrom ), Day( dateFrom ), 23, 59, 59 );

				return {
					  to   = dateTo
					, from = dateFrom
				};
			break;

			case "lastweek":
				var currentDateTime = _getCurrentDateTime();
				var offsetDay       = DayOfWeek( currentDateTime );
				var dateFrom        = DateAdd( "d", 1 - offsetDay - 7, CreateDateTime( Year( currentDateTime ), Month( currentDateTime ), Day( currentDateTime ) ) );
				var dateTo          = DateAdd( "d", 6                , CreateDateTime( Year( dateFrom )       , Month( dateFrom )       , Day( dateFrom ), 23, 59, 59 ) );

				return {
					  to   = dateTo
					, from = dateFrom
				};
			break;

			case "thisweek":
				var currentDateTime = _getCurrentDateTime();
				var offsetDay       = DayOfWeek( currentDateTime );
				var dateFrom        = DateAdd( "d", 1 - offsetDay, CreateDateTime( Year( currentDateTime ), Month( currentDateTime ), Day( currentDateTime ) ) );
				var dateTo          = DateAdd( "d", 6            , CreateDateTime( Year( dateFrom )       , Month( dateFrom )       , Day( dateFrom ), 23, 59, 59 ) );

				return {
					  to   = dateTo
					, from = dateFrom
				};
			break;

			case "nextweek":
				var currentDateTime = _getCurrentDateTime();
				var offsetDay       = DayOfWeek( currentDateTime );
				var dateFrom        = DateAdd( "d", 1 - offsetDay + 7, CreateDateTime( Year( currentDateTime ), Month( currentDateTime ), Day( currentDateTime ) ) );
				var dateTo          = DateAdd( "d", 6                , CreateDateTime( Year( dateFrom )       , Month( dateFrom )       , Day( dateFrom ), 23, 59, 59 ) );

				return {
					  to   = dateTo
					, from = dateFrom
				};
			break;

			case "lastmonth":
				var currentDateTime  = _getCurrentDateTime();
				var firstOfThisMonth = CreateDateTime( Year( currentDateTime ), Month( currentDateTime ), 1, 0, 0, 0 );
				var firstOfLastMonth = DateAdd( "m", -1, firstOfThisMonth );
				var endOfLastMonth   = DateAdd( "d", -1, CreateDateTime( Year( firstOfThisMonth ), Month( firstOfThisMonth ), Day( firstOfThisMonth ), 23, 59, 59 ) );

				return {
					  to   = endOfLastMonth
					, from = firstOfLastMonth
				};
			break;

			case "thismonth":
				var currentDateTime  = _getCurrentDateTime();
				var firstOfThisMonth = CreateDateTime( Year( currentDateTime ), Month( currentDateTime ), 1, 0, 0, 0 );
				var firstOfNextMonth = DateAdd( "m", 1, firstOfThisMonth );
				var endOfThisMonth   = DateAdd( "d", -1, CreateDateTime( Year( firstOfNextMonth ), Month( firstOfNextMonth ), Day( firstOfNextMonth ), 23, 59, 59 ) );

				return {
					  to   = endOfThisMonth
					, from = firstOfThisMonth
				};
			break;

			case "nextmonth":
				var currentDateTime    = _getCurrentDateTime();
				var nextMonthDate      = DateAdd( "m", 1, currentDateTime );
				var firstOfNextMonth   = CreateDateTime( Year( nextMonthDate ), Month( nextMonthDate ), 1, 0, 0, 0);
				var firstOfNext2Months = DateAdd( "m", 1, firstOfNextMonth );
				var endOfNextMonth     = DateAdd( "d", -1, CreateDateTime( Year( firstOfNext2Months ), Month( firstOfNext2Months ), Day( firstOfNext2Months ), 23, 59, 59 ) );

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