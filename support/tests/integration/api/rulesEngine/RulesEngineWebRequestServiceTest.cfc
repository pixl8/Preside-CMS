component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "evaluateCondition()", function(){
			it( "should call condition service's 'evaluateCondition()' method, passing in the condition ID and using the 'webrequest' context", function(){
				var service     = _getService();
				var conditionId = CreateUUId();

				mockConditionService.$( "evaluateCondition", true );

				expect( service.evaluateCondition( conditionId ) ).toBeTrue();
				expect( mockConditionService.$callLog().evaluateCondition.len() ).toBe( 1 );
				expect( mockConditionService.$callLog().evaluateCondition[1].conditionId ?: "" ).toBe( conditionId );
				expect( mockConditionService.$callLog().evaluateCondition[1].context ?: "" ).toBe( "webrequest" );
			} );
		} );
	}

// PRIVATE HELPERS
	private any function _getService() {
		mockConditionService = CreateEmptyMock( "preside.system.services.rulesEngine.RulesEngineConditionService" );

		var service = createMock( object=new preside.system.services.rulesEngine.RulesEngineWebRequestService(
			  conditionService    = mockConditionService
		) );

		return service;
	}
}