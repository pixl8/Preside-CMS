component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "convertTimePeriodToDateRange()", function(){
			var service = _getService();

			it( "should return empty struct when empty string passed", function(){
				expect( service.convertTimePeriodToDateRange( "" ) ).toBe( {} );
			} );

			it( "should return empty struct when invalid json passed", function(){
				expect( service.convertTimePeriodToDateRange( "{" ) ).toBe( {} );
			} );

			it( "should return empty struct when json struct with 'alltime' period type passed", function(){
				expect( service.convertTimePeriodToDateRange( SerializeJson( { type="alltime", blah="test" } ) ) ).toBe( {} );
			} );

			it( "should return date1 and date2 as dateTo and dateFrom, when type is 'between'", function(){
				var timePeriod = { type="between", date1="2016-01-01 00:00", date2="2016-01-02 01:00" };
				var json       = SerializeJson( timePeriod );
				var range      = { from=timePeriod.date1, to=timePeriod.date2 };

				expect( service.convertTimePeriodToDateRange( json ) ).toBe( range );
			} );

			it( "should return an empty struct when type is 'between' but date1 is not a valid date", function(){
				var timePeriod = { type="between", date1="", date2="2016-01-02 01:00" };
				var json       = SerializeJson( timePeriod );

				expect( service.convertTimePeriodToDateRange( json ) ).toBe( {} );
			} );

			it( "should return an empty struct when type is 'between' but date2 is not a valid date", function(){
				var timePeriod = { type="between", date1="2016-01-01 00:00", date2="" };
				var json       = SerializeJson( timePeriod );

				expect( service.convertTimePeriodToDateRange( json ) ).toBe( {} );
			} );

			it( "should return date1 as from and currentDate as to when type is 'since'", function(){
				var timePeriod = { type="since", date1="2015-07-01 03:00" };
				var json       = SerializeJson( timePeriod );
				var range      = { from=timePeriod.date1, to=nowish };

				expect( service.convertTimePeriodToDateRange( json ) ).toBe( range );
			} );

			it( "should return an empty struct when type is 'since' but date1 is not a valid date", function(){
				var timePeriod = { type="since", date1="" };
				var json       = SerializeJson( timePeriod );

				expect( service.convertTimePeriodToDateRange( json ) ).toBe( {} );
			} );

			it( "should return date1 as 'to' and no 'from' when type is 'before'", function(){
				var timePeriod = { type="before", date1="2015-07-01 03:00" };
				var json       = SerializeJson( timePeriod );
				var range      = { to=timePeriod.date1 };

				expect( service.convertTimePeriodToDateRange( json ) ).toBe( range );
			} );

			it( "should return an empty struct when type is 'before' but date1 is not a valid date", function(){
				var timePeriod = { type="before", date1="" };
				var json       = SerializeJson( timePeriod );

				expect( service.convertTimePeriodToDateRange( json ) ).toBe( {} );
			} );

			it( "should return date1 as 'from' and no 'to' when type is 'after'", function(){
				var timePeriod = { type="after", date1="2015-07-01 03:00" };
				var json       = SerializeJson( timePeriod );
				var range      = { from=timePeriod.date1 };

				expect( service.convertTimePeriodToDateRange( json ) ).toBe( range );
			} );

			it( "should return an empty struct when type is 'after' but date1 is not a valid date", function(){
				var timePeriod = { type="after", date1="" };
				var json       = SerializeJson( timePeriod );

				expect( service.convertTimePeriodToDateRange( json ) ).toBe( {} );
			} );

			it( "should return date1 as to and currentDate as from when type is 'until'", function(){
				var timePeriod = { type="until", date1="2015-07-01 03:00" };
				var json       = SerializeJson( timePeriod );
				var range      = { to=timePeriod.date1, from=nowish };

				expect( service.convertTimePeriodToDateRange( json ) ).toBe( range );
			} );

			it( "should return an empty struct when type is 'until' but date1 is not a valid date", function(){
				var timePeriod = { type="until", date1="" };
				var json       = SerializeJson( timePeriod );

				expect( service.convertTimePeriodToDateRange( json ) ).toBe( {} );
			} );

			it( "should return currentDate as 'to' and a 3 days prior to current date from when type is 'recent', unit is 'd' and measure is 3", function(){
				var timePeriod = { type="recent", unit="d", measure=3 };
				var json       = SerializeJson( timePeriod );
				var fromDate   = DateAdd( 'd', -3, nowish );
				var range      = { from=CreateDate( Year( fromDate ), Month( fromDate ), Day( fromDate ) ), to=nowish };

				expect( service.convertTimePeriodToDateRange( json ) ).toBe( range );
			} );

			it( "should return empty struct when type is 'recent' but unit is not a valid unit", function(){
				var timePeriod = { type="recent", unit="sadfjhasd", measure=3 };
				var json       = SerializeJson( timePeriod );

				expect( service.convertTimePeriodToDateRange( json ) ).toBe( {} );
			} );

			it( "should return empty struct when type is 'recent' but measure is not present", function(){
				var timePeriod = { type="recent", unit="d" };
				var json       = SerializeJson( timePeriod );

				expect( service.convertTimePeriodToDateRange( json ) ).toBe( {} );
			} );

			it( "should return currentDate as 'from' and 2 years after current date as 'to' when type is 'upcoming', unit is 'yyyy' and measure is 2", function(){
				var timePeriod = { type="upcoming", unit="yyyy", measure=2 };
				var json       = SerializeJson( timePeriod );
				var fromDate   = DateAdd( 'yyyy', 2, nowish );
				var range      = { to=CreateDate( Year( fromDate ), Month( fromDate ), Day( fromDate ) ), from=nowish };

				expect( service.convertTimePeriodToDateRange( json ) ).toBe( range );
			} );


			it( "should return empty struct when type is 'upcoming' but unit is not a valid unit", function(){
				var timePeriod = { type="upcoming", unit="sadfjhasd", measure=3 };
				var json       = SerializeJson( timePeriod );

				expect( service.convertTimePeriodToDateRange( json ) ).toBe( {} );
			} );

			it( "should return empty struct when type is 'upcoming' but measure is not present", function(){
				var timePeriod = { type="upcoming", unit="d" };
				var json       = SerializeJson( timePeriod );

				expect( service.convertTimePeriodToDateRange( json ) ).toBe( {} );
			} );

			/*

			*/
		} );
	}

// PRIVATE HELPERS
	private any function _getService(){
		var service = createMock( object=new preside.system.services.rulesEngine.RulesEngineTimePeriodService() );

		variables.nowish = Now();
		variables.beginningOfTime = "0000-00-00 00:00";
		service.$( "_getCurrentDateTime", nowish );

		return service;
	}
}