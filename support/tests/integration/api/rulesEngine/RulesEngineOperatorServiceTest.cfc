component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "compareStrings()", function(){
			it( "should return true when operator is 'eq' and leftHandSide and rightHandSide are equal", function(){
				var service = _getService();

				expect( service.compareStrings( "tEst", "eq", "test" ) ).toBeTrue();
			} );

			it( "should return false when operator is 'eq' and leftHandSide and rightHandSide are not equal", function(){
				var service = _getService();

				expect( service.compareStrings( "tEst", "eq", "testify" ) ).toBeFalse();
			} );

			it( "should return false when operator is 'neq' and leftHandSide and rightHandSide are equal", function(){
				var service = _getService();

				expect( service.compareStrings( "tEst", "neq", "test" ) ).toBeFalse();
			} );

			it( "should return true when operator is 'neq' and leftHandSide and rightHandSide are not equal", function(){
				var service = _getService();

				expect( service.compareStrings( "tEst", "neq", "testify" ) ).toBeTrue();
			} );

			it( "should return true when operator is 'contains' and leftHandSide string contains rightHandSide", function(){
				var service = _getService();

				expect( service.compareStrings( "this is a test", "contains", "s a t" ) ).toBeTrue();
			} );

			it( "should return false when operator is 'contains' and leftHandSide string does not contain rightHandSide", function(){
				var service = _getService();

				expect( service.compareStrings( "this is a test", "contains", "nonsense" ) ).toBeFalse();
			} );

			it( "should return true when operator is 'startsWith' and leftHandSide string starts with rightHandSide", function(){
				var service = _getService();

				expect( service.compareStrings( "this is a test", "startsWith", "thi" ) ).toBeTrue();
			} );

			it( "should return false when operator is 'startsWith' and leftHandSide string does not start with rightHandSide", function(){
				var service = _getService();

				expect( service.compareStrings( "this is a test", "startsWith", "is a test" ) ).toBeFalse();
			} );

			it( "should return true when operator is 'endsWith' and leftHandSide string ends with rightHandSide", function(){
				var service = _getService();

				expect( service.compareStrings( "this is a test", "endsWith", " a test" ) ).toBeTrue();
			} );

			it( "should return false when operator is 'endsWith' and leftHandSide string does not end with rightHandSide", function(){
				var service = _getService();

				expect( service.compareStrings( "this is a test", "endsWith", "is a " ) ).toBeFalse();
			} );

			it( "should return false when an invalid operator is used", function(){
				var service = _getService();

				expect( service.compareStrings( "this is a test", CreateUUId(), "is a " ) ).toBeFalse();
			} );
		} );
	}

// PRIVATE HELPERS
	private any function _getService(){
		return new preside.system.services.rulesEngine.RulesEngineOperatorService();
	}
}