component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "evaluateCondition()", function(){
			it( "should call condition service's 'evaluateCondition()' method, passing in the condition ID and using the 'webrequest' context", function(){
				var service     = _getService();
				var conditionId = CreateUUId();

				mockRequestContext.$( "getValue" ).$args( name="presidePage", defaultValue={}, private=true ).$results( {} );
				mockConditionService.$( "evaluateCondition", true );
				mockLoginService.$( "getLoggedInUserDetails", {} );

				expect( service.evaluateCondition( conditionId ) ).toBeTrue();
				expect( mockConditionService.$callLog().evaluateCondition.len() ).toBe( 1 );
				expect( mockConditionService.$callLog().evaluateCondition[1].conditionId ?: "" ).toBe( conditionId );
				expect( mockConditionService.$callLog().evaluateCondition[1].context ?: "" ).toBe( "webrequest" );
			} );

			it( "should call condition service's 'evaluateCondition()' method, passing in details about the current page in the payload", function(){
				var service     = _getService();
				var dummyPage   = { blah=CreateUUId(), test=true };
				var conditionId = CreateUUId();

				mockRequestContext.$( "getValue" ).$args( name="presidePage", defaultValue={}, private=true ).$results( dummyPage );
				mockConditionService.$( "evaluateCondition", true );
				mockLoginService.$( "getLoggedInUserDetails", {} );

				expect( service.evaluateCondition( conditionId ) ).toBeTrue();
				expect( mockConditionService.$callLog().evaluateCondition.len() ).toBe( 1 );
				expect( mockConditionService.$callLog().evaluateCondition[1].payload.page ?: {} ).toBe( dummyPage );
			} );

			it( "should pass information about the logged in user in the evaluateCondition payload", function(){
				var service     = _getService();
				var conditionId = CreateUUId();
				var dummyUser   = { id=CreateUUId(), login_id="test" };

				mockRequestContext.$( "getValue" ).$args( name="presidePage", defaultValue={}, private=true ).$results( {} );
				mockConditionService.$( "evaluateCondition", true );
				mockLoginService.$( "getLoggedInUserDetails", dummyUser );

				expect( service.evaluateCondition( conditionId ) ).toBeTrue();
				expect( mockConditionService.$callLog().evaluateCondition[1].payload.user ?: {} ).toBe( dummyUser );
			} );
		} );
	}

// PRIVATE HELPERS
	private any function _getService() {
		mockConditionService = CreateEmptyMock( "preside.system.services.rulesEngine.RulesEngineConditionService" );
		mockLoginService     = CreateEmptyMock( "preside.system.services.websiteUsers.WebsiteLoginService" );
		mockRequestContext   = CreateStub();

		var service = createMock( object=new preside.system.services.rulesEngine.RulesEngineWebRequestService(
			  conditionService    = mockConditionService
			, websiteLoginService = mockLoginService
		) );

		service.$( "$getRequestContext", mockRequestContext );

		return service;
	}
}