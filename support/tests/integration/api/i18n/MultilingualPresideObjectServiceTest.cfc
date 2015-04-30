component extends="tests.resources.HelperObjects.PresideTestCase" {

	function test01_listLanguages_shouldPullLanguagesFromSettings_andMergeWithDataFromLanguagePresideObject() {
		var svc = _getService();
		var mockSettings = {
			  default_language     = "id-2"
			, additional_languages = "id-3,id-1,id-4"
		};
		var mockDbData = QueryNew( 'id,iso_code,name,native_name,left_to_right', 'varchar,varchar,varchar,varchar,bit', [
			 [ "id-1", "fr", "French" , "francais", 0 ]
			,[ "id-3", "en", "English", "English" , 0 ]
			,[ "id-2", "ar", "Arabic" , "Arbic"   , 1 ]
			,[ "id-4", "de", "German" , "Deutche" , 0 ]
		] );
		var expectedResult = [
			  { id="id-2", iso_code="ar", name="Arabic" , native_name="Arbic"   , left_to_right=1, default=true , sortOrder=1 }
			, { id="id-3", iso_code="en", name="English", native_name="English" , left_to_right=0, default=false, sortOrder=2 }
			, { id="id-1", iso_code="fr", name="French" , native_name="francais", left_to_right=0, default=false, sortOrder=3 }
			, { id="id-4", iso_code="de", name="German" , native_name="Deutche" , left_to_right=0, default=false, sortOrder=4 }
		];

		var languagesCombined = ListToArray( mockSettings.additional_languages );
		languagesCombined.prepend( mockSettings.default_language );
		mockSystemConfigurationService.$( "getCategorySettings" ).$args( "multilingual" ).$results( mockSettings );
		mockLanguageDao.$( "selectData" ).$args( filter={ id=languagesCombined } ).$results( mockDbData );

		super.assertEquals( expectedResult, svc.listLanguages() );
	}

	function test02_listLanguages_shouldNotIncludeDefaultLanguage_whenFlagToExcludeDefaultIsSetToTrue() {
		var svc = _getService();
		var mockSettings = {
			  default_language     = "id-2"
			, additional_languages = "id-3,id-1,id-4"
		};
		var mockDbData = QueryNew( 'id,iso_code,name,native_name,left_to_right', 'varchar,varchar,varchar,varchar,bit', [
			 [ "id-1", "fr", "French" , "francais", 0 ]
			,[ "id-3", "en", "English", "English" , 0 ]
			,[ "id-4", "de", "German" , "Deutche" , 0 ]
		] );
		var expectedResult = [
			  { id="id-3", iso_code="en", name="English", native_name="English" , left_to_right=0, default=false, sortOrder=1 }
			, { id="id-1", iso_code="fr", name="French" , native_name="francais", left_to_right=0, default=false, sortOrder=2 }
			, { id="id-4", iso_code="de", name="German" , native_name="Deutche" , left_to_right=0, default=false, sortOrder=3 }
		];

		var languagesCombined = ListToArray( mockSettings.additional_languages );
		mockSystemConfigurationService.$( "getCategorySettings" ).$args( "multilingual" ).$results( mockSettings );
		mockLanguageDao.$( "selectData" ).$args( filter={ id=languagesCombined } ).$results( mockDbData );

		super.assertEquals( expectedResult, svc.listLanguages( includeDefault=false ) );
	}

	// function test03_getTranslationStatus_shouldReturnStatusesOfTranslationsForEachNonDefaultLanguage_byLookingUpTranslationRecords() {
	// 	var svc = _getService();
	// 	var mockLanguages = [{},{},{}];
	// }

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
		super.assert( actualProperties.keyExists( "_translation_active"        ) );

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
			  relationship  = "many-to-one"
			, relatedto     = "multilingual_language"
			, required      = true
			, uniqueindexes = "translation|2"
			, indexes       = ""
			, ondelete      = "error"
			, onupdate      = "cascade"
			, generator     = "none"
		}, actualProperties._translation_language.getMemento() );

		super.assertEquals( {
			  required      = false
			, type          = "boolean"
			, dbtype        = "boolean"
			, default       = false
			, uniqueindexes = ""
			, indexes       = ""
			, relationship  = "none"
			, relatedto     = "none"
			, generator     = "none"
			, maxLength     = 0
		}, actualProperties._translation_active.getMemento() );
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

		super.assertEquals( "prop1,prop6,_translation_source_record,_translation_language,_translation_active", multilingualObject.meta.dbFieldList ?: ""  );
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
		mockRelationshipGuidance       = getMockbox().createEmptyMock( "preside.system.services.presideObjects.RelationshipGuidance" );
		mockSystemConfigurationService = getMockbox().createEmptyMock( "preside.system.services.configuration.SystemConfigurationService" );
		mockLanguageDao                = getMockbox().createStub();

		return new preside.system.services.i18n.MultilingualPresideObjectService(
			  relationshipGuidance       = mockRelationshipGuidance
			, systemConfigurationService = mockSystemConfigurationService
			, languageDao                = mockLanguageDao
		);
	}

	private any function _dummyObjectProperty() {
		return new preside.system.services.presideObjects.property( argumentCollection=arguments );
	}
}