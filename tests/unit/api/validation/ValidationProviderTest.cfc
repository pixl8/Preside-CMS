component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// TESTS
	function test01_listValidators_shouldReturnEmptyArray_whenNoValidatorsAdded(){
		var provider = _getProvider();
		var result   = provider.listValidators();

		super.assertEquals( [], result );
	}

	function test02_listValidators_shouldReturnAnArrayOfValidatorNames_whenValidatorsAdded(){
		var provider = _getProvider();

		provider.addValidator( name="test" , method="test" );
		provider.addValidator( name="test2", method="test2" );
		provider.addValidator( name="test3", method="test3" );

		super.assertEquals( [ "test", "test2", "test3" ], provider.listValidators() );
	}

	function test03_validatorExists_shouldReturnFalse_whenValidatorDoesNotExist(){
		var provider = _getProvider();

		super.assertFalse( provider.validatorExists( name="someNonExistantValidator" ), "validatorExists() returned true for non existant validator" );
	}

	function test04_validatorExistsShouldReturnTrue_whenValidatorExists(){
		var provider = _getProvider();

		provider.addValidator( name="test" , method="test" );
		provider.addValidator( name="test2", method="test2" );
		provider.addValidator( name="test3", method="test3" );

		super.assertTrue( provider.validatorExists( name="test3" ), "validatorExists() returned false for existant validator" );
	}

	function test05_runValidator_shouldRunTheGivenValidatorOnTheCfcSuppliedToTheProviderConstructor(){
		var providerCfc = new tests.resources.ValidationProvider.SimpleProvider();
		var provider    = _getProvider( providerCfc );
		var result      = "";

		provider.addValidator( name="test" , method="validator1" );
		provider.addValidator( name="test2", method="validator2" );

		result = provider.runValidator(
			  name      = "test"
			, fieldName = "someField"
			, value     = "test"
			, data      = { someField = "test" }
			, params    = { justTesting=true }
		);

		super.assertEquals( "test", result );
	}

	function test06_runValidator_shouldThrowInformativeError_whenValidatorDoesNotExist(){
		var errorThrown = false;
		var provider    = _getProvider();

		try {
			provider.runValidator(
				  name      = "test"
				, fieldName = "someField"
				, value     = "test"
				, data      = { someField = "test" }
				, params    = { justTesting=true }
			);
		} catch ( "ValidationProvider.missingValidator" e ) {
			super.assertEquals( "The validator, [test], does not exist for this Validation Provider" , e.message );
			errorThrown = true;
		}

		super.assert( errorThrown, "An informative error was not thrown" );
	}

	function test07_runValidator_shouldThrowInformativeError_whenRequiredCustomParametersAreNotPassed(){
		var errorThrown = false;
		var providerCfc = new tests.resources.ValidationProvider.SimpleProvider();
		var provider    = _getProvider( providerCfc );

		provider.addValidator( name="test" , method="validator2", params=[{name="param1", required=true }] );

		try {
			provider.runValidator(
				  name      = "test"
				, fieldName = "someField"
				, value     = "test"
				, data      = { someField = "test" }
				, params    = {}
			);
		} catch ( "ValidationProvider.missingValidatorParam" e ) {
			super.assertEquals( "The required parameter, [param1], for the [test] validator is missing. This should be defined in the validation rule for this field ([someField])" , e.message );
			errorThrown = true;
		}

		super.assert( errorThrown, "An informative error was not thrown" );
	}

	function test08_getValidatorParamValues_shouldReturnArrayOfCustomParameterValuesWithDefaultsMixedInWithPassedValues(){
		var providerCfc    = new tests.resources.ValidationProvider.SimpleProvider();
		var provider       = _getProvider( providerCfc );
		var providedParams = { param1="test" };
		var expectedResult = [ "test", "param2", "" ];
		var actualResult   = "";

		provider.addValidator( name="test" , method="validator2", params=[
			{ name="param1"      , required=false, default="param1" },
			{ name="anotherParam", required=false, default="param2" },
			{ name="param3"      , required=false }
		]);

		actualResult = provider.getValidatorParamValues( name="test", params=providedParams );

		super.assertEquals( expectedResult, actualResult );
	}

	function test09_getValidatorParamValues_shouldReturnEmptyArray_whenValidatorDoesNotExist(){
		var providerCfc    = new tests.resources.ValidationProvider.SimpleProvider();
		var provider       = _getProvider( providerCfc );
		var expectedResult = [];
		var actualResult   = provider.getValidatorParamValues( name="test", params={} );

		super.assertEquals( expectedResult, actualResult );
	}

	function test10_getJsFunction_shouldReturnEmptyString_whenNoJsFunctionRegisteredForAValidator(){
		var providerCfc    = new tests.resources.ValidationProvider.SimpleProvider();
		var provider       = _getProvider( providerCfc );

		provider.addValidator( name="test", method="validator2" );

		super.assertEquals( "", provider.getJsFunction( name="test" ) );
	}

	function test11_getJsFunction_shouldReturnRegisteredJsFunctionForValidator(){
		var providerCfc = new tests.resources.ValidationProvider.SimpleProvider();
		var provider    = _getProvider( providerCfc );
		var jsFunction  = "function(){ return true; }";

		provider.addValidator( name="test", method="validator2", jsFunction=jsFunction );

		super.assertEquals( jsFunction, provider.getJsFunction( name="test" ) );
	}

	function test12_getJsFunction_shouldReturnEmptyString_whenValidatorDoesNotExist(){
		var providerCfc    = new tests.resources.ValidationProvider.SimpleProvider();
		var provider       = _getProvider( providerCfc );

		provider.addValidator( name="test", method="validator2" );

		super.assertEquals( "", provider.getJsFunction( name="blah" ) );
	}

	function test13_getDefaultMessage_shouldReturnEmptyString_whenNoMessageRegisteredForAValidator(){
		var providerCfc    = new tests.resources.ValidationProvider.SimpleProvider();
		var provider       = _getProvider( providerCfc );

		provider.addValidator( name="test", method="validator2" );

		super.assertEquals( "", provider.getDefaultMessage( name="test" ) );
	}

	function test14_getDefaultMessage_shouldReturnRegisteredMessageForValidator(){
		var providerCfc = new tests.resources.ValidationProvider.SimpleProvider();
		var provider    = _getProvider( providerCfc );
		var message     = "Hello world!";

		provider.addValidator( name="test", method="validator2", defaultMessage=message );

		super.assertEquals( message, provider.getDefaultMessage( name="test" ) );
	}

	function test15_getDefaultMessage_shouldReturnEmptyString_whenValidatorDoesNotExist(){
		var providerCfc    = new tests.resources.ValidationProvider.SimpleProvider();
		var provider       = _getProvider( providerCfc );

		provider.addValidator( name="test", method="validator2", defaultMessage="Test message" );

		super.assertEquals( "", provider.getDefaultMessage( name="someValidatorThatDoesNotExist" ) );
	}

// PRIVATE HELPERS
	private any function _getProvider( any sourceCfc ){
		if ( not StructKeyExists( arguments, "sourceCfc" ) ) {
			arguments.sourceCfc = this;
		}
		return new preside.system.services.validation.ValidationProvider( sourceCfc = arguments.sourceCfc );
	}
}