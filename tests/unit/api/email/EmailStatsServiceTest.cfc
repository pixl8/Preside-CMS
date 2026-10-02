component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "regenerateSummaryData()", function(){
			it( "should rebuild bot open and bot click counters from activity rows", function(){
				var service    = _getService();
				var templateId = CreateUUId();
				var seen       = [];

				mockActivityDao.$( "selectData" ).$callback( function(){
					if ( arguments.getSqlAndParamsOnly ?: false ) {
						return { sql="select 1", params=[] };
					}

					if ( IsStruct( arguments.filter ?: "" ) && StructKeyExists( arguments.filter, "activity_type" ) ) {
						seen.append( arguments.filter.activity_type );
					}

					return QueryNew( "n,hour_start,link,link_body,link_title" );
				} );

				service.regenerateSummaryData( templateId=templateId );

				expect( seen ).toInclude( "bot_open" );
				expect( seen ).toInclude( "bot_click" );
				expect( mockLoggingService.$callLog().recomputeOpenAndClickCounts.len() ).toBe( 1 );
				expect( mockLoggingService.$callLog().recomputeOpenAndClickCounts[ 1 ].templateId ).toBe( templateId );
			} );
		} );
	}

	private any function _getService() {
		var service = createMock( object=new preside.system.services.email.EmailStatsService() );
		var wirebox = CreateStub();
		var coldbox = CreateStub();

		mockActivityDao    = CreateStub();
		mockTemplateDao    = CreateStub();
		mockStatsDao       = CreateStub();
		mockSqlRunner      = CreateStub();
		mockLoggingService = CreateStub();

		service.$property( propertyName="activityDao"    , mock=mockActivityDao );
		service.$property( propertyName="templateDao"    , mock=mockTemplateDao );
		service.$property( propertyName="statsSummaryDao", mock=mockStatsDao );
		service.$property( propertyName="sqlRunner"      , mock=mockSqlRunner );

		mockStatsDao.$( "deleteData" );
		mockTemplateDao.$( "updateData" );
		mockActivityDao.$( "getDsn", "dummy" );
		mockSqlRunner.$( "runSql", QueryNew( "n,hour_start" ) );
		mockLoggingService.$( "recomputeOpenAndClickCounts" );

		coldbox.$( "getWirebox", wirebox );
		wirebox.$( "getInstance" ).$args( "emailLoggingService" ).$results( mockLoggingService );
		service.$( "$getColdbox", coldbox );
		service.$( "$systemOutput" );

		return service;
	}

}
