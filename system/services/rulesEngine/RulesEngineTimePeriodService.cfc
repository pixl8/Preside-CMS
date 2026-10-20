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

			case "betweenago":
				return _convertRelativeBetweenToDateRange(
					  currentDateTime = currentDateTime
					, measure         = timePeriod.measure  ?: ""
					, unit            = timePeriod.unit     ?: ""
					, measure2        = timePeriod.measure2 ?: ""
					, unit2           = timePeriod.unit2    ?: ""
					, direction       = -1
				);
			break;

			case "betweenupcoming":
				return _convertRelativeBetweenToDateRange(
					  currentDateTime = currentDateTime
					, measure         = timePeriod.measure  ?: ""
					, unit            = timePeriod.unit     ?: ""
					, measure2        = timePeriod.measure2 ?: ""
					, unit2           = timePeriod.unit2    ?: ""
					, direction       = 1
				);
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

			case "futureequal":
				try {
					var futureDate = DateAdd( "d", Val( timePeriod.measure ?: "" ), currentDateTime );
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
				return { to=currentDateTime };
			break;

			case "pastminus":
				try {
					return { to = DateAdd( ( timePeriod.unit ?: "" ), 0-Val( timePeriod.measure ?: "" ), currentDateTime ) };
				} catch( any e ) {
					return {};
				}
			break;

			case "pastequal":
				try {
					var pastDate = DateAdd( "d", 0-Val( timePeriod.measure ?: "" ), currentDateTime );
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

			case "lastyear":
				var firstOfThisYear = CreateDateTime( Year( currentDateTime ), 1, 1, 0, 0, 0 );
				var firstOfLastYear = DateAdd( "yyyy", -1, firstOfThisYear );
				var endOfLastYear   = DateAdd( "s"   , -1, firstOfThisYear );

				return {
					  to   = endOfLastYear
					, from = firstOfLastYear
				};
			break;

			case "thisyear":
				var firstOfThisYear = CreateDateTime( Year( currentDateTime ), 1, 1, 0, 0, 0 );
				var firstOfNextYear = DateAdd( "yyyy", 1, firstOfThisYear );
				var endOfThisYear   = DateAdd( "s"   , -1, firstOfNextYear );

				return {
					  to   = endOfThisYear
					, from = firstOfThisYear
				};
			break;

			case "nextyear":
				var nextYearDate      = DateAdd( "yyyy", 1, currentDateTime );
				var firstOfNextYear   = CreateDateTime( Year( nextYearDate ), 1, 1, 0, 0, 0);
				var firstOfNext2Years = DateAdd( "yyyy",  1, firstOfNextYear );
				var endOfNextYear     = DateAdd( "s"   , -1, firstOfNext2Years );

				return {
					  to   = endOfNextYear
					, from = firstOfNextYear
				};
			break;
		}

		return {};
	}


// private helpers
	private date function _getCurrentDateTime() {
		return Now();
	}

	private struct function _convertRelativeBetweenToDateRange(
		  required date    currentDateTime
		,          string  measure   = ""
		,          string  unit      = ""
		,          string  measure2  = ""
		,          string  unit2     = ""
		,          numeric direction = -1
	) {
		var fromDate = "";
		var toDate   = "";
		var unitTo   = Len( Trim( arguments.unit2 ) ) ? arguments.unit2 : arguments.unit;

		try {
			fromDate = DateAdd( arguments.unit, arguments.direction * Val( arguments.measure  ), arguments.currentDateTime );
			toDate   = DateAdd( unitTo        , arguments.direction * Val( arguments.measure2 ), arguments.currentDateTime );
		} catch( any e ) {
			return {};
		}

		if ( fromDate > toDate ) {
			var swapDate = fromDate;
			fromDate     = toDate;
			toDate       = swapDate;
		}

		return {
			  from = fromDate
			, to   = toDate
		};
	}

}