component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "validateCondition()", function(){
			it( "should return false when passed condition is not valid JSON", function(){
				var service          = _getService();
				var validationResult = _newValidationResult();

				expect( service.validateCondition(
					  condition        = "{lsakjdfljd.test"
					, validationResult = validationResult
					, context          = "any"
				) ).toBeFalse();
			} );

			it( "should add a general validation result error explaining invalid JSON packet error when condition is invalid json", function(){
				var service          = _getService();
				var validationResult = _newValidationResult();

				service.validateCondition(
					  condition        = "{lsakjdfljd.test"
					, validationResult = validationResult
					, context          = "any"
				);

				expect( validationResult.getGeneralMessage() ).toBe( "The passed condition was malformed and could not be read" );
			} );
		} );
	}

// PRIVATE HELPERS
	private any function _getService() {
		variables.mockColdbox = createStub();

		var service = createMock( object=new preside.system.services.rulesEngine.RulesEngineConditionService() );

		service.$( "$getColdbox", mockColdbox );

		return service;
	}

	private any function _newValidationResult() {
		return new preside.system.services.validation.ValidationResult();
	}
}