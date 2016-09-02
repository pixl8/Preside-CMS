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
		}

		return {};
	}


// private helpers
	private date function _getCurrentDateTime() {
		return Now();
	}

}