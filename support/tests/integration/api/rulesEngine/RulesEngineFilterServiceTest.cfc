component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "prepareFilter()", function(){
			it( "should amalgamate the generated filters from an expression array into a single plain SQL string filter + set of params", function(){
				var service = _getService();
				var dummyFilters = [
					  [ { filter=CreateUUId(), filterParams={ param1=CreateUUId() } }, { filter=CreateUUId(), filterParams={ param2=CreateUUId() } } ]
					, [ { filter=CreateUUId(), filterParams={ param3=CreateUUId() } } ]
					, [ { filter=CreateUUId(), filterParams={ param4=CreateUUId() } } ]
					, [ { filter=CreateUUId(), filterParams={ param5=CreateUUId() } } ]
				];
				var dummySqlFilters = [
					  "filter1"
					, "filter2"
					, "filter3"
					, "filter4"
					, "filter5"
				];
				var expectedSql = "( ( filter1 and filter2 ) and ( filter3 or ( filter4 and filter5 ) ) )";
				var expectedParams = {
					  param1 = dummyFilters[1][1].filterParams.param1
					, param2 = dummyFilters[1][2].filterParams.param2
					, param3 = dummyFilters[2][1].filterParams.param3
					, param4 = dummyFilters[3][1].filterParams.param4
					, param5 = dummyFilters[4][1].filterParams.param5
				}
				var dummyCondition = [{
					  expression = "test.expression"
					, fields     = { test=CreateUUId(), _is=true }
				},
				"and",[{
						  expression = "another.expression"
						, fields     = { test=CreateUUId(), _is=true }
					},"or",[{
							  expression = "another.expression"
							, fields     = { test=CreateUUId(), _is=true }
							},"and",{
							  expression = "another.expression"
							, fields     = { test=CreateUUId(), _is=true } }
							]
					]
				];

				mockExpressionService.$( "prepareExpressionFilters" ).$args( expressionId=dummyCondition[1].expression, objectName=dummyObject, configuredFields = dummyCondition[1].fields, filterPrefix="" ).$results( dummyFilters[1] );
				mockExpressionService.$( "prepareExpressionFilters" ).$args( expressionId=dummyCondition[3][1].expression, objectName=dummyObject, configuredFields = dummyCondition[3][1].fields, filterPrefix="" ).$results( dummyFilters[2] );
				mockExpressionService.$( "prepareExpressionFilters" ).$args( expressionId=dummyCondition[3][3][1].expression, objectName=dummyObject, configuredFields = dummyCondition[3][3][1].fields, filterPrefix="" ).$results( dummyFilters[3] );
				mockExpressionService.$( "prepareExpressionFilters" ).$args( expressionId=dummyCondition[3][3][3].expression, objectName=dummyObject, configuredFields = dummyCondition[3][3][3].fields, filterPrefix="" ).$results( dummyFilters[4] );

				mockDbAdapter.$( "getClauseSql" ).$args( filter=dummyFilters[1][1].filter, tableAlias=dummyObject ).$results( dummySqlFilters[1] );
				mockDbAdapter.$( "getClauseSql" ).$args( filter=dummyFilters[1][2].filter, tableAlias=dummyObject ).$results( dummySqlFilters[2] );
				mockDbAdapter.$( "getClauseSql" ).$args( filter=dummyFilters[2][1].filter, tableAlias=dummyObject ).$results( dummySqlFilters[3] );
				mockDbAdapter.$( "getClauseSql" ).$args( filter=dummyFilters[3][1].filter, tableAlias=dummyObject ).$results( dummySqlFilters[4] );
				mockDbAdapter.$( "getClauseSql" ).$args( filter=dummyFilters[4][1].filter, tableAlias=dummyObject ).$results( dummySqlFilters[5] );

				var result = service.prepareFilter(
					  objectName      = dummyObject
					, expressionArray = dummyCondition
				);

				expect( result.filter ?: "" ).toBe( expectedSql );
				expect( result.filterParams ?: {} ).toBe( expectedParams );
			} );

			it( "should switch to using a having clause if *any* of the genrated expression filters uses a having clause", function(){
				var service = _getService();
				var dummyFilters = [
					  [ { filter=CreateUUId(), filterParams={ param1=CreateUUId() } }, { filter=CreateUUId(), filterParams={ param2=CreateUUId() } } ]
					, [ { filter=CreateUUId(), filterParams={ param3=CreateUUId() }, having=CreateUUId() } ]
					, [ { filter=CreateUUId(), filterParams={ param4=CreateUUId() } } ]
					, [ { filter=CreateUUId(), filterParams={ param5=CreateUUId() } } ]
				];
				var dummySqlFilters = [
					  "filter1"
					, "filter2"
					, "filter3"
					, "filter4"
					, "filter5"
				];
				var expectedSql = "( ( filter1 and filter2 ) and ( ( filter3 and #dummyFilters[2][1].having# ) or ( filter4 and filter5 ) ) )";
				var filterPrefix = CreateUUId();
				var expectedParams = {
					  param1 = dummyFilters[1][1].filterParams.param1
					, param2 = dummyFilters[1][2].filterParams.param2
					, param3 = dummyFilters[2][1].filterParams.param3
					, param4 = dummyFilters[3][1].filterParams.param4
					, param5 = dummyFilters[4][1].filterParams.param5
				}
				var dummyCondition = [{
					  expression = "test.expression"
					, fields     = { test=CreateUUId(), _is=true }
				},
				"and",[{
						  expression = "another.expression"
						, fields     = { test=CreateUUId(), _is=true }
					},"or",[{
							  expression = "another.expression"
							, fields     = { test=CreateUUId(), _is=true }
							},"and",{
							  expression = "another.expression"
							, fields     = { test=CreateUUId(), _is=true } }
							]
					]
				];

				mockExpressionService.$( "prepareExpressionFilters" ).$args( expressionId=dummyCondition[1].expression, objectName=dummyObject, configuredFields = dummyCondition[1].fields, filterPrefix=filterPrefix ).$results( dummyFilters[1] );
				mockExpressionService.$( "prepareExpressionFilters" ).$args( expressionId=dummyCondition[3][1].expression, objectName=dummyObject, configuredFields = dummyCondition[3][1].fields, filterPrefix=filterPrefix ).$results( dummyFilters[2] );
				mockExpressionService.$( "prepareExpressionFilters" ).$args( expressionId=dummyCondition[3][3][1].expression, objectName=dummyObject, configuredFields = dummyCondition[3][3][1].fields, filterPrefix=filterPrefix ).$results( dummyFilters[3] );
				mockExpressionService.$( "prepareExpressionFilters" ).$args( expressionId=dummyCondition[3][3][3].expression, objectName=dummyObject, configuredFields = dummyCondition[3][3][3].fields, filterPrefix=filterPrefix ).$results( dummyFilters[4] );

				mockDbAdapter.$( "getClauseSql" ).$args( filter=dummyFilters[1][1].filter, tableAlias=dummyObject ).$results( dummySqlFilters[1] );
				mockDbAdapter.$( "getClauseSql" ).$args( filter=dummyFilters[1][2].filter, tableAlias=dummyObject ).$results( dummySqlFilters[2] );
				mockDbAdapter.$( "getClauseSql" ).$args( filter=dummyFilters[2][1].filter, tableAlias=dummyObject ).$results( dummySqlFilters[3] );
				mockDbAdapter.$( "getClauseSql" ).$args( filter=dummyFilters[3][1].filter, tableAlias=dummyObject ).$results( dummySqlFilters[4] );
				mockDbAdapter.$( "getClauseSql" ).$args( filter=dummyFilters[4][1].filter, tableAlias=dummyObject ).$results( dummySqlFilters[5] );

				var result = service.prepareFilter(
					  objectName      = dummyObject
					, expressionArray = dummyCondition
					, filterPrefix    = filterPrefix
				);

				expect( result.having ?: "" ).toBe( expectedSql );
				expect( result.filter ?: "" ).toBe( "" );
				expect( result.filterParams ?: {} ).toBe( expectedParams );
			} );
		} );

		describe( "selectData()", function(){
			it( "prepare the filter for the given condition and pass all arguments through to a presideObjectService.selectData() call, returning the result", function(){
				var service         = _getService();
				var expressionArray = [ "whatever" ];
				var dummyFilter     = { filter="hello!", filterparams={ test=CreateUUId() } };
				var extraFilters    = [ { filter="blah", filterParams={} } ];
				var dummyResult     = QueryNew( 'test', 'varchar', [[CreateUUId()]]);
				var expectedFilters = Duplicate( extraFilters );
				var randomArgs      = { someArgument=CreateUUId(), anotherArg=CreateUUId() };

				expectedFilters.append( dummyFilter );

				service.$( "prepareFilter" ).$args(
					  objectName      = dummyObject
					, expressionArray = expressionArray
				).$results( dummyFilter );

				mockPresideObjectService.$( "selectData", dummyResult );

				expect( service.selectData(
					  argumentCollection = randomArgs
					, objectName         = dummyObject
					, expressionArray    = expressionArray
					, extraFilters       = extraFilters
				) ).toBe( dummyResult );

				expect( mockPresideObjectService.$callLog().selectData.len() ).toBe( 1 );
				expect( mockPresideObjectService.$callLog().selectData[1] ).toBe( {
					  objectName   = dummyObject
					, extraFilters = expectedFilters
					, someArgument = randomArgs.someArgument
					, anotherArg   = randomArgs.anotherArg
					, autoGroupBy  = true
					, distinct     = true
				} );
			} );
		} );

		describe( "getMatchingRecordCount()", function(){
			it( "call selectData with a selectFields value that gets a Count() of records and returns the count", function(){
				var service               = _getService();
				var expressionArray       = [ "whatever" ];
				var dummySelectDataResult = 41;

				service.$( "selectData", dummySelectDataResult );

				expect( service.getMatchingRecordCount(
					  objectName         = dummyObject
					, expressionArray    = expressionArray
				) ).toBe( 41 );
				expect( service.$callLog().selectData.len() ).toBe( 1 );
				expect( service.$callLog().selectData[1] ).toBe( {
					  objectName      = dummyObject
					, expressionArray = expressionArray
					, recordCountOnly = true
				} );
			} );
		} );

	}

// PRIVATE HELPERS
	private any function _getService() {
		mockcoldbox              = CreateEmptyMock( "preside.system.coldboxModifications.Controller" );
		mockPresideObjectService = CreateEmptyMock( "preside.system.services.presideObjects.PresideObjectService" );
		mockExpressionService    = CreateEmptyMock( "preside.system.services.rulesEngine.RulesEngineExpressionService" );
		mockDbAdapter            = CreateStub();
		dummyObject              = CreateUUId();

		var service = CreateMock( object=new preside.system.services.rulesEngine.RulesEngineFilterService(
			expressionService = mockExpressionService
		) );

		service.$( "$getPresideObjectService", mockPresideObjectService );
		service.$( "$getColdbox", mockColdbox );
		mockPresideObjectService.$( "getDbAdapterForObject" ).$args( dummyObject ).$results( mockDbAdapter );

		return service;
	}

}
