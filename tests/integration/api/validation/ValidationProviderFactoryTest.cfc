component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// TESTS
	function test01_createProvider_shouldReturnProviderWithNoValidators_givenASourceCfcWithNoValidatorMethods(){
		var factory = _getFactory();
		var provider = factory.createProvider( sourceCfc = this );

		super.assert( IsInstanceOf( provider, "preside.system.services.validation.ValidationProvider" ), "CreateProvider did not return a provider object" );
		super.assertEquals( [], provider.listValidators() );
	}

	function test02_createProvider_shouldReadValidatorsFromComponentMetaDataAndLoadIntoReturnedProvider(){
		var factory   = _getFactory();
		var sourceCfc = new tests.resources.ValidationProvider.SimpleProvider();
		var provider  = factory.createProvider( sourceCfc = sourceCfc );

		super.assert( IsInstanceOf( provider, "preside.system.services.validation.ValidationProvider" ), "CreateProvider did not return a provider object" );
		super.assertEquals( [ "validator1", "validator2", "validator3" ], provider.listValidators() );

		super.assert( provider.validatorExists( "validator1" ) );
		super.assert( provider.validatorExists( "validator2" ) );
		super.assert( provider.validatorExists( "validator3" ) );
		super.assertEquals( "message for validator1", provider.getDefaultMessage( "validator1" ) );
		super.assertEquals( "message for validator2", provider.getDefaultMessage( "validator2" ) );
		super.assertEquals( "message for validator3", provider.getDefaultMessage( "validator3" ) );
		super.assert( provider.runValidator( name="validator2" ) );
	}

	function test03_createProvider_shouldTreatRegisterAllPublicMethodsAsValidators_whenSourceComponentIsFlaggedAsValidationProvider(){
		var factory   = _getFactory();
		var sourceCfc = new tests.resources.ValidationProvider.ImplicitProvider();
		var provider  = factory.createProvider( sourceCfc = sourceCfc );

		super.assertEquals( [ "validator1", "validator2", "validator3" ], provider.listValidators() );
	}

	function test04_createProvider_shouldRegisterValidatorParamsBasedOnMethodArguments(){
		var factory   = _getFactory();
		var sourceCfc = new tests.resources.ValidationProvider.ImplicitProvider();
		var provider  = factory.createProvider( sourceCfc = sourceCfc );

		try {
			provider.runValidator(
				  name      = "validator3"
				, fieldName = "someField"
				, data      = { someField = "test" }
				, params    = {}
			);
		} catch ( "ValidationProvider.missingValidatorParam" e ) {
			errorThrown = true;
		}

		super.assert( errorThrown, "Required parameters were not auto detected and registered" );
	}

	function test05_createProvider_shouldRegisterJavascriptFunctionsByConventionOfMethodEndingWithUnderScoreJs(){
		var factory   = _getFactory();
		var sourceCfc = new tests.resources.ValidationProvider.SimpleProviderWithJsMethods();
		var provider  = factory.createProvider( sourceCfc = sourceCfc );

		super.assertEquals( [ "validator1", "validator2", "validator3" ], provider.listValidators() );

		super.assertEquals( "", provider.getJsFunction( "validator1" ) );
		super.assertEquals( "function( value, element, params ){ return true; }", provider.getJsFunction( "validator2" ) );
		super.assertEquals( "function( value, element, params ){ return false; }", provider.getJsFunction( "validator3" ) );
	}

	function test06_createProvider_shouldThrowInformativeError_whenJsFunctionDoesNotReturnAString(){
		var factory     = _getFactory();
		var sourceCfc   = new tests.resources.ValidationProvider.SimpleProviderWithJsMethodThatReturnsNonString();
		var errorThrown = false;

		try {
			factory.createProvider( sourceCfc = sourceCfc );
		} catch( "ValidationProvider.badJsReturnValue" e ){
			super.assertEquals( "A non-string value was returned from the javascript validator function, [someValidator_js]. This method should return a string containing a javascript function.", e.message );
			errorThrown = true;
		}

		super.assert( errorThrown, "An informative error was not thrown" );

	}

// PRIVATE HELPERS
	private any function _getFactory(){
		return new preside.system.services.validation.ValidationProviderFactory();
	}
}