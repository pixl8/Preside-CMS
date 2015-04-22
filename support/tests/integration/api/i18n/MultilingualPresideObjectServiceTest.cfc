component extends="tests.resources.HelperObjects.PresideTestCase" {

	function test06_createTranslationObject_shouldReturnAnObjectWhosTableNameIsTheSourceObjectPrependedWith_translation() {
		var svc               = _getService();
		var dummyProps        = StructNew( "linked" );

		dummyProps.prop1 = _dummyObjectProperty( name="prop1", multilingual=true );
		dummyProps.prop2 = _dummyObjectProperty( name="prop2", multilingual=false );
		dummyProps.prop3 = _dummyObjectProperty( name="prop3" );
		dummyProps.prop4 = _dummyObjectProperty( name="prop4" );
		dummyProps.prop5 = _dummyObjectProperty( name="prop5", multilingual=true );
		dummyProps.prop6 = _dummyObjectProperty( name="prop6", multilingual=true );

		var dummyObject = { meta={ name="app.preside-objects.myobject", tableName="test_table_name", multilingual=true, properties=dummyProps } };
		var multilingualObject = svc.createTranslationObject( "myobject", dummyObject );

		super.assertEquals( "_translation_test_table_name", multilingualObject.meta.tableName ?: "" );
	}

	function test07_createTranslationObject_shouldReturnAnObjectWithOnlyMultilingualPropertiesFromTheSourceObjectCarriedOver(){
		var svc        = _getService();
		var dummyProps = StructNew( "linked" );

		dummyProps.prop1 = _dummyObjectProperty( name="prop1", multilingual=true );
		dummyProps.prop2 = _dummyObjectProperty( name="prop2", multilingual=false );
		dummyProps.prop3 = _dummyObjectProperty( name="prop3" );
		dummyProps.prop4 = _dummyObjectProperty( name="prop4" );
		dummyProps.prop5 = _dummyObjectProperty( name="prop5", multilingual=true );
		dummyProps.prop6 = _dummyObjectProperty( name="prop6", multilingual=true );

		var dummyObject = { meta={ name="app.preside-objects.myobject", multilingual=true, properties=dummyProps } };
		var multilingualObject = svc.createTranslationObject( "myobject", dummyObject );
		var actualProperties   = multilingualObject.meta.properties ?: {};

		super.assert( actualProperties.keyExists( "prop1") );
		super.assert( actualProperties.keyExists( "prop5") );
		super.assert( actualProperties.keyExists( "prop6") );
		super.assertFalse( actualProperties.keyExists( "prop2") );
		super.assertFalse( actualProperties.keyExists( "prop3") );
		super.assertFalse( actualProperties.keyExists( "prop4") );
	}

	function test08_createTranslationObject_shouldAddFieldsForRelatingToSourceRecordAndDefiningLanguage() {
		var svc                = _getService();
		var dummyObject        = { meta={ name="app.preside-objects.myobject", tableName="test_table_name", multilingual=true, properties={} } };
		var multilingualObject = svc.createTranslationObject( "myobject", dummyObject );
		var actualProperties   = multilingualObject.meta.properties ?: {};

		super.assert( actualProperties.keyExists( "_translation_source_record" ) );
		super.assert( actualProperties.keyExists( "_translation_language"      ) );

		super.assertEquals( {
			  relationship  = "many-to-one"
			, relatedto     = "myobject"
			, required      = true
			, uniqueindexes = "translation|1"
			, indexes       = ""
			, ondelete      = "cascade"
			, onupdate      = "cascade"
			, generator     = "none"
		}, actualProperties._translation_source_record.getMemento() );

		super.assertEquals( {
			  required      = true
			, type          = "string"
			, dbtype        = "varchar"
			, maxlength     = 8
			, uniqueindexes = "translation|2"
			, indexes       = ""
			, relationship  = "none"
			, relatedto     = "none"
			, generator     = "none"
		}, actualProperties._translation_language.getMemento() );
	}

	function test09_createTranslationObject_shouldModifyDbFieldListBasedOnAdditionalFieldsAndMultilingualFields(){
		var svc        = _getService();
		var dummyProps = StructNew( "linked" );

		dummyProps.prop1 = _dummyObjectProperty( name="prop1", multilingual=true );
		dummyProps.prop2 = _dummyObjectProperty( name="prop2", multilingual=false );
		dummyProps.prop3 = _dummyObjectProperty( name="prop3" );
		dummyProps.prop4 = _dummyObjectProperty( name="prop4" );
		dummyProps.prop5 = _dummyObjectProperty( name="prop5", multilingual=true );
		dummyProps.prop6 = _dummyObjectProperty( name="prop6", multilingual=true );

		var dummyObject = { meta={ name="app.preside-objects.myobject", multilingual=true, properties=dummyProps, dbFieldList="prop1,prop2,prop4,prop6" } };
		var multilingualObject = svc.createTranslationObject( "myobject", dummyObject );

		super.assertEquals( "prop1,prop6,_translation_source_record,_translation_language", multilingualObject.meta.dbFieldList ?: ""  );
	}

	function test10_createTranslationObject_shouldAddUniqueIndexToTheObjectDefinition() {
		var svc                = _getService();
		var dummyObject        = { meta={ name="app.preside-objects.myobject", tableName="test_table_name", multilingual=true, properties={} } };
		var multilingualObject = svc.createTranslationObject( "myobject", dummyObject );

		super.assertEquals( { unique=true, fields="_translation_source_record,_translation_language" }, ( multilingualObject.meta.indexes[ "ux_translation_myobject_translation" ] ?: {} ) );
	}

	function test11_decorateMultilingualObject_shouldAddOneToManyPropertyToSourceObject_toAidWithTranslationLookupQueries(){
		var svc                = _getService();
		var dummyObject        = { meta={ name="app.preside-objects.myobject", tableName="test_table_name", multilingual=true, properties={} } };

		svc.decorateMultilingualObject( "myobject", dummyObject );

		super.assert( dummyObject.meta.properties.keyExists( "_translations" ) );
		super.assertEquals( {
 			  relationship    = "one-to-many"
			, relatedto       = "_translation_myobject"
			, relationshipKey = "_translation_source_record"
			, required        = false
			, uniqueindexes   = ""
			, indexes         = ""
			, generator       = "none"
		}, dummyObject.meta.properties._translations.getMemento() );
	}

// PRIVATE HELPERS
	private any function _getService() {
		return new preside.system.services.i18n.MultilingualPresideObjectService();
	}

	private any function _dummyObjectProperty() {
		return new preside.system.services.presideObjects.property( argumentCollection=arguments );
	}
}