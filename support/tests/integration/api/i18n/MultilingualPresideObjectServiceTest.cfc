component extends="tests.resources.HelperObjects.PresideTestCase" {

	function test01_isObjectMultilingual_shouldReturnFalseWhenMultiLingualFlagNotSet() {
		var svc         = _getService();
		var dummyObject = { name="myobject" };

		super.assertFalse( svc.isObjectMultilingual( dummyObject ) );
	}

	function test02_isObjectMultilingual_shouldReturnTrueWhenMultiLingualFlagIsSetToTrue() {
		var svc         = _getService();
		var dummyObject = { name="myobject", multilingual=true };

		super.assertTrue( svc.isObjectMultilingual( dummyObject ) );
	}

	function test03_isObjectMultilingual_shouldReturnFalseWhenMultiLingualFlagIsSetToFalse() {
		var svc         = _getService();
		var dummyObject = { name="myobject", multilingual=true };

		super.assertTrue( svc.isObjectMultilingual( dummyObject ) );
	}

	function test04_listMultilingualObjectProperties_shouldReturnArrayOfPropertiesThatAreFlaggedAsMultilingualInAnObjectDefinition(){
		var svc               = _getService();
		var expectedProperies = [ "prop1", "prop5", "prop6" ]
		var dummyProps        = StructNew( "linked" );

		dummyProps.prop1 = _dummyObjectProperty( name="prop1", multilingual=true );
		dummyProps.prop2 = _dummyObjectProperty( name="prop2", multilingual=false );
		dummyProps.prop3 = _dummyObjectProperty( name="prop3" );
		dummyProps.prop4 = _dummyObjectProperty( name="prop4" );
		dummyProps.prop5 = _dummyObjectProperty( name="prop5", multilingual=true );
		dummyProps.prop6 = _dummyObjectProperty( name="prop6", multilingual=true );

		var dummyObject = { name="myobject", multilingual=true, properties=dummyProps };

		super.assertEquals( expectedProperies, svc.listMultilingualObjectProperties( dummyObject ) );
	}

// PRIVATE HELPERS
	private any function _getService() {
		return new preside.system.services.i18n.MultilingualPresideObjectService();
	}

	private any function _dummyObjectProperty() {
		return new preside.system.services.presideObjects.property( argumentCollection=arguments );
	}
}