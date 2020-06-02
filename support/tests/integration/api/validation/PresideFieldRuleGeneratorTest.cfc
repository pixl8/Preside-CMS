component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

	function setup(){
		mockPresideObjectService = getMockbox().createEmptyMock( "preside.system.services.presideObjects.PresideObjectService" );
		mockLogger               = _getTestLogger();
		mockResourceBundleSvc    = getMockbox().createEmptyMock( "preside.system.services.i18n.ResourceBundleService" );
		mockAssetManagerSvc      = getMockbox().createEmptyMock( "preside.system.services.assetManager/AssetManagerService" );

		mockPresideObjectService.$( "getResourceBundleUriRoot", "preside-objects.test:" );
		mockResourceBundleSvc.$( "getResource", "somevalue" );

		generator = new preside.system.services.validation.PresideFieldRuleGenerator(
			  presideObjectService  = mockPresideObjectService
			, logger                = mockLogger
			, resourceBundleService = mockResourceBundleSvc
			, assetManagerService   = mockAssetManagerSvc
		);
	}

// TESTS
	function test01_getRulesForField_shouldReturnARequiredRule_whenFieldIsRequired(){
		var expected = [{ fieldName="aField", validator="required", message="preside-objects.test:validation.aField.required.message" }];
		var rules     = generator.getRulesForField( objectName="test", fieldName="aField", fieldAttributes={
			required = true
		} );

		super.assertEquals( expected, rules );
	}

	function test02_getRulesForField_shouldNotReturnRequiredRule_whenFieldIsNotRequired(){
		var expected = [];
		var rules     = generator.getRulesForField( objectName="test", fieldName="aField", fieldAttributes={
			required = false
		} );

		super.assertEquals( expected, rules );
	}

	function test03_getRulesForField_shouldReturnMinLengthValidator_whenFieldHasMinLengthAttributeAndNoMaxLengthAttribute(){
		var expected  = [{ fieldName="test_field", validator="minLength", params={ length=30 }, message="preside-objects.test:validation.test_field.minLength.message" } ];
		var rules     = generator.getRulesForField( objectName="test", fieldName="test_field", fieldAttributes={
			minLength = "30"
		} );

		super.assertEquals( expected, rules );
	}

	function test04_getRulesForField_shouldReturnMaxLengthValidator_whenFieldHasMaxLengthAttributeAndNoMinLengthAttribute(){
		var expected  = [{ fieldName="another_test", validator="maxLength", params={ length=30 }, message="preside-objects.test:validation.another_test.maxLength.message" } ];
		var rules     = generator.getRulesForField( objectName="test", fieldName="another_test", fieldAttributes={
			maxLength = "30"
		} );

		super.assertEquals( expected, rules );
	}

	function test05_getRulesForField_shouldReturnRangeLengthValidator_whenFieldHasBothMaxAndMinLengthAttributes(){
		var expected  = [{ fieldName="another_test", validator="rangeLength", params={ minLength=5, maxLength=24 }, message="preside-objects.test:validation.another_test.rangeLength.message" } ];
		var rules     = generator.getRulesForField( objectName="test", fieldName="another_test", fieldAttributes={
			  minLength = "5"
			, maxLength = "24"
		} );

		super.assertEquals( expected, rules );
	}

	function test06_getRulesForField_shouldReturnMinValueValidator_whenFieldHasMinValueAttributeAndNoMaxValueAttribute(){
		var expected  = [{ fieldName="test_field", validator="min", params={ min=30 }, message="preside-objects.test:validation.test_field.min.message" } ];
		var rules     = generator.getRulesForField( objectName="test", fieldName="test_field", fieldAttributes={
			minValue = "30"
		} );

		super.assertEquals( expected, rules );
	}

	function test07_getRulesForField_shouldReturnMaxValueValidator_whenFieldHasMaxValueAttributeAndNoMinValueAttribute(){
		var expected  = [{ fieldName="another_test", validator="max", params={ max=30 }, message="preside-objects.test:validation.another_test.max.message" } ];
		var rules     = generator.getRulesForField( objectName="test", fieldName="another_test", fieldAttributes={
			maxValue = "30"
		} );

		super.assertEquals( expected, rules );
	}

	function test08_getRulesForField_shouldReturnRangeValidator_whenFieldHasBothMaxAndMinValueAttributes(){
		var expected  = [{ fieldName="another_test", validator="range", params={ min=5, max=24 }, message="preside-objects.test:validation.another_test.range.message" } ];
		var rules     = generator.getRulesForField( objectName="test", fieldName="another_test", fieldAttributes={
			  minValue = "5"
			, maxValue = "24"
		} );

		super.assertEquals( expected, rules );
	}

	function test09_getRulesForField_shouldReturnUniqueIndexValidators_whenFieldHasUniqueIndexesAttribute(){
		var expected  = [
			{ fieldName="somefield", validator="presideObjectUniqueIndex", params={ objectName="test", fields="field1,field2,someField" }, message="preside-objects.test:validation.somefield.presideObjectUniqueIndex.message" },
			{ fieldName="somefield", validator="presideObjectUniqueIndex", params={ objectName="test", fields="someField" }, message="preside-objects.test:validation.somefield.presideObjectUniqueIndex.message" },
		];
		var rules     = "";

		mockPresideObjectService.$( "getObjectProperties", {
			  field1    = { name="field1", uniqueIndexes="index1|2" }
			, field2    = { name="field2", uniqueIndexes="index1|2,index3|2" }
			, someField = { name="someField", uniqueIndexes="index1|3,index2,index3|1" }
		} );

		rules = generator.getRulesForField( objectName="test", fieldName="somefield", fieldAttributes={
			uniqueIndexes = "index1|3,index2,index3|1"
		} );

		super.assertEquals( expected, rules );
	}

	function test10_getRulesForField_shouldReturnNumberValidator_whenFieldIsNumericType_andFormatAttributeNotEqualToInteger(){
		var expected  = [{ fieldName="numeric_field", validator="number", message="preside-objects.test:validation.numeric_field.number.message" }];
		var rules     = generator.getRulesForField( objectName="test", fieldName="numeric_field", fieldAttributes={
			type = "numeric"
		} );

		super.assertEquals( expected, rules );
	}

	function test11_getRulesForField_shouldReturnDigitsValidator_whenFieldIsNumericType_andFormatEqualToInteger(){
		var expected  = [{ fieldName="numeric_field", validator="digits", message="preside-objects.test:validation.numeric_field.digits.message" }];
		var rules     = generator.getRulesForField( objectName="test", fieldName="numeric_field", fieldAttributes={
			  type   = "numeric"
			, format = "integer"
		} );

		super.assertEquals( expected, rules );
	}

	function test12_getRulesForField_shouldReturnDateValidator_whenFieldIsDateType(){
		var expected  = [{ fieldName="some_datefield", validator="date", message="preside-objects.test:validation.some_datefield.date.message" }];
		var rules     = generator.getRulesForField( objectName="test", fieldName="some_datefield", fieldAttributes={
			type = "date", dbtype="date"
		} );

		super.assertEquals( expected, rules );
	}

	function test13_getRulesForField_shouldReturnValidatorMatchingFormatValue_whenFieldIsStringTypeAndFormatIsNonEmpty(){
		var expected  = [{ fieldName="a_field", validator="whatever", message="preside-objects.test:validation.a_field.whatever.message" }];
		var rules     = generator.getRulesForField( objectName="test", fieldName="a_field", fieldAttributes={
			  type   = "string"
			, format = "whatever"
		} );

		super.assertEquals( expected, rules );
	}

	function test14_getRulesForField_shouldReturnRegexValidator_whenFieldIsStringAndFormatHasRegexPrefix(){
		var expected  = [{ fieldName="a_field", validator="match", params={ regex="^M[0-9]{8}$" }, message="preside-objects.test:validation.a_field.match.message" }];
		var rules     = generator.getRulesForField( objectName="test", fieldName="a_field", fieldAttributes={
			  type   = "string"
			, format = "regex:^M[0-9]{8}$"
		} );

		super.assertEquals( expected, rules );
	}

	function test15_getRulesForField_shouldnOTReturnMaxLengthValidator_whenFieldHasMaxLengthAttributEqualToZero(){
		var expected  = [];
		var rules     = generator.getRulesForField( objectName="test", fieldName="another_test", fieldAttributes={
			maxLength = "0"
		} );

		super.assertEquals( expected, rules );
	}

	function test16_getRulesForField_shouldNotReturnARequiredRule_whenFieldIsRequiredButHasAGeneratorNotEqualToNone(){
		var expected = [];
		var rules     = generator.getRulesForField( objectName="test", fieldName="aField", fieldAttributes={
			required = true, generator="UUID"
		} );

		super.assertEquals( expected, rules );
	}

	function test17_getRulesForField_shouldNotReturnRequiredRules_ForCoreDateFields(){
		var expected = [];
		var rules     = generator.getRulesForField( objectName="test", fieldName="datecreated", fieldAttributes={
			required = true
		} );

		super.assertEquals( expected, rules );

		rules = generator.getRulesForField( objectName="test", fieldName="datemodified", fieldAttributes={
			required = true
		} );
		super.assertEquals( expected, rules );
	}


	function test18_getRulesForField_shouldNotReturnMessage_whenConventionBasedResourceBundleKeyDoesNotExist(){
		var expected  = [{ fieldName="a_field", validator="match", params={ regex="^M[0-9]{8}$" } }];
		var rules     = "";

		mockResourceBundleSvc.$( "getResource", "" );

		rules = generator.getRulesForField( objectName="test", fieldName="a_field", fieldAttributes={
			  type   = "string"
			, format = "regex:^M[0-9]{8}$"
		} );

		super.assertEquals( expected, rules );
	}
}