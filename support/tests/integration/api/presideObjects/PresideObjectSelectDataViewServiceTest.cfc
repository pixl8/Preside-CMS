component extends="tests.resources.HelperObjects.PresideBddTestCase"{

	function run(){

		describe( "getViewArgs()", function(){

			it( "should run convention based handler to return selectData() arguments in a struct result", function(){
				var service = _getService();
				var view    = "activeArticles";
				var mockResult = {
					  selectFields = [ CreateUUId() ]
					, useCache     = false
				};
				mockColdbox.$( "handlerExists" ).$args( "selectDataViews.#view#" ).$results( true );
				mockColdbox.$( "runEvent" ).$args(
					  event          = "selectDataViews.#view#"
					, private        = true
					, prepostExempt  = true
				).$results( mockResult );

				expect( service.getViewArgs( view ) ).toBe( mockResult );
			} );

			it( "should throw an informative error when no handler exists for the view", function(){
				var service = _getService();
				var view    = "nonExistent";

				mockColdbox.$( "handlerExists" ).$args( "selectDataViews.#view#" ).$results( false );

				expect( function(){
					service.getViewArgs( view )
				} ).toThrow( "presideobjectselectdataviews.missing.view" );
			} );

			it( "should throw an informative error when the handler does not return a struct", function(){
				var service = _getService();
				var view    = "activeArticles";
				mockColdbox.$( "handlerExists" ).$args( "selectDataViews.#view#" ).$results( true );
				mockColdbox.$( "runEvent" ).$args(
					  event          = "selectDataViews.#view#"
					, private        = true
					, prepostExempt  = true
				).$results( NullValue() );

				expect( function(){
					service.getViewArgs( view )
				} ).toThrow( "presideobjectselectdataviews.bad.view.result" );
			} );

		} );

		describe( "makeUniqueParams()", function() {
			it( "should add a uuid to any params found in SQL and params combo", function(){
				var service = _getService();
				var uid = CreateUUId();
				var sqlAndParams = {
					  sql = "blah blah blah test = :param1 and blah = :param_oh_boy"
					, params = [
						  { name="param1", type="cf_sql_varchar", value=CreateUUId() }
						, { name="param_oh_boy", type="cf_sql_varchar", value=CreateUUId() }
					  ]
				};

				service.$( "_uuid", uid );

				expect( service.makeUniqueParams( Duplicate( sqlAndParams ) ) ).toBe( {
					  sql = "blah blah blah test = :param1#uid# and blah = :param_oh_boy#uid#"
					, params = [
						  { name="param1#uid#", type="cf_sql_varchar", value=sqlAndParams.params[1].value }
						, { name="param_oh_boy#uid#", type="cf_sql_varchar", value=sqlAndParams.params[2].value }
					  ]
				} );
			} );
		} );

		describe( "getSqlAndParams()", function(){
			it( "should return result of viewArgs passed to selectData with sqlAndParamsOnly added + params made unique", function(){
				var service = _getService();
				var view    = "activeArticles";
				var mockArgs = {
					  selectFields = [ CreateUUId() ]
					, useCache     = false
				};
				var mockResult = {
					  sql    = "blah blah test #CreateUUId()#"
					, params = { test="this" }
				};
				var mockUniqueResult = {
					  sql    = "blah blah test #CreateUUId()#"
					, params = { test_yes="this" }
				};

				service.$( "getViewArgs" ).$args( view ).$results( mockArgs );
				mockPresideObjectService.$( "selectData" ).$args(
					  selectFields        = mockArgs.selectFields
					, useCache            = false
					, getSqlAndParamsOnly = true
				).$results( mockResult );
				service.$( "makeUniqueParams" ).$args( mockResult ).$results( mockUniqueResult );

				expect( service.getSqlAndParams( view ) ).toBe( mockUniqueResult );
			} );
		} );
	}

	private any function _getService() {
		var service = CreateMock( object=new preside.system.services.presideObjects.PresideObjectSelectDataViewService(
		) );

		variables.mockColdbox = CreateStub();
		variables.mockPresideObjectService = CreateStub();
		service.$( "$getColdbox", mockColdbox );
		service.$( "$getPresideObjectService", mockPresideObjectService );

		return service;
	}
}