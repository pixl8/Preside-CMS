component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// TESTS
	function test01_validated_shouldReturnTrue_forANewlyInstantiatedResult(){
		var result = _getResult();

		super.assert( result.validated() );
	}

	function test02_validated_shouldReturnFalse_whenGeneralErrorMessageAddedToInstance(){
		var result = _getResult();

		result.setGeneralMessage( 'something crappy happened' );

		super.assertFalse( result.validated() );
	}

	function test03_validated_shouldReturnFalse_whenIndividualFieldErrorAdded(){
		var result = _getResult();

		result.addError( fieldName="someField", message="type it rite!" );

		super.assertFalse( result.validated() );
	}

	function test04_listErrorFields_shouldReturnArrayOfAddedErrorFields(){
		var result = _getResult();

		result.addError( fieldName="someField1", message="type it rite!" );
		result.addError( fieldName="someField2", message="type it rite!" );
		result.addError( fieldName="someField3", message="type it rite!" );

		super.assertEquals( ["someField1", "someField2", "someField3" ], result.listErrorFields() );
	}

	function test05_listErrorFields_shouldReturnEmptyArray_whenNoErrorsAdded(){
		var result = _getResult();

		super.assertEquals( [], result.listErrorFields() );
	}

	function test06_getError_shouldReturnMessageForGivenField(){
		var result = _getResult();

		result.addError( fieldName="someField1", message="type it rite!1" );
		result.addError( fieldName="someField2", message="type it rite!2" );
		result.addError( fieldName="someField3", message="type it rite!3" );

		super.assertEquals( "type it rite!2", result.getError( fieldName="someField2" ) );
	}

	function test07_getError_shouldReturnEmptyString_whenErrorForFieldDoesNotExist(){
		var result = _getResult();

		super.assertEquals( "", result.getError( fieldName="someField2" ) );
	}

	function test08_fieldHasError_shouldReturnFalse_whenPassedFieldDoesNotHaveAnError(){
		var result = _getResult();

		super.assertFalse( result.fieldHasError( fieldName="someField2" ) );
	}

	function test09_fieldHasError_shouldReturnTrue_whenPassedFieldHasAnError(){
		var result = _getResult();

		result.addError( fieldName="someField3", message="type it rite!3" );

		super.assert( result.fieldHasError( fieldName="someField3" ) );
	}

	function test10_listErrorParameterValues_shouldReturnEmptyArray_whenErrorForFieldDoesNotExist(){
		var result = _getResult();

		result.addError( fieldName="someField3", message="type it rite!3" );

		super.assertEquals( [], result.listErrorParameterValues( "idonotexist" ) );
	}

	function test11_listErrorParameterValues_shouldReturnEmptyArray_whenNoParametersAddedForErroringField(){
		var result = _getResult();

		result.addError( fieldName="someField3", message="type it rite!3" );

		super.assertEquals( [], result.listErrorParameterValues( "someField3" ) );
	}

	function test12_listErrorParameterValues_shouldReturnArrayOfSetParamatersForTheErroringField(){
		var result     = _getResult();
		var testParams = ["test","params","here",123];

		result.addError( fieldName="erroringField", message="validation:some.field.error", params=testParams );

		super.assertEquals( testParams, result.listErrorParameterValues( "erroringField" ) );
	}

// PRIVATE HELPERS
	private any function _getResult(){
		return new preside.system.services.validation.ValidationResult();
	}
}