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
		svc.$( "$getPresideCategorySettings" ).$args( "multilingual" ).$results( mockSettings );
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
		svc.$( "$getPresideCategorySettings" ).$args( "multilingual" ).$results( mockSettings );
		mockLanguageDao.$( "selectData" ).$args( filter={ id=languagesCombined } ).$results( mockDbData );

		super.assertEquals( expectedResult, svc.listLanguages( includeDefault=false ) );
	}

	function test03_getTranslationStatus_shouldReturnStatusesOfTranslationsForEachNonDefaultLanguage_byLookingUpTranslationRecords() {
		var svc           = _getService();
		var objectName    = "someobject";
		var recordId      = CreateUUId();
		var mockLanguages = [{id="lang_1"},{id="lang_2"},{id="lang_3"}];
		var mockDbResult  = QueryNew('_translation_language,_translation_active', "varchar,bit", [
			 [ "lang_3", 0 ]
			,[ "lang_1", 1 ]
		]);
		var expectedResult = [
			  { id="lang_1", status="active" }
			, { id="lang_2", status="notstarted" }
			, { id="lang_3", status="inprogress" }
		];

		svc.$( "listLanguages" ).$args( includeDefault=false ).$results( mockLanguages );
		mockPresideObjectService.$( "selectData" ).$args(
			  selectFields = [ "_translation_language", "_translation_active" ]
			, objectName   = "_translation_" & objectName
			, filter       = { _translation_source_record=recordId }
		).$results( mockDbResult );

		super.assertEquals( expectedResult, svc.getTranslationStatus( objectName, recordId ) );
	}

	function test04_getLanguage_shouldReturnAnEmptyStruct_whenTheLanguageIsNotAnActivelyTranslatableLanguage() {
		var svc = _getService();

		svc.$( "listLanguages", [{id="id-1", name="French", default=true }] );

		super.assert( svc.getLanguage( "id-5" ).isEmpty() );
	}

	function test05_getLanguage_shouldReturnDetailsOfActivelyTranslatableLanguage() {
		var svc = _getService();
		var languages = [{id="id-1", name="French", default=true }, {id="id-2", name="English", default=false}]

		svc.$( "listLanguages", languages );

		super.assertEquals( languages[ 2 ], svc.getLanguage( "id-2" ) );
	}

	function test06_createTranslationObject_shouldReturnAnObjectWhosTableNameIsTheSourceObjectPrependedWith_translation() {
		var svc               = _getService();
		var dummyProps        = StructNew( "linked" );

		dummyProps.prop1 = { name="prop1", multilingual=true };
		dummyProps.prop2 = { name="prop2", multilingual=false };
		dummyProps.prop3 = { name="prop3" };
		dummyProps.prop4 = { name="prop4" };
		dummyProps.prop5 = { name="prop5", multilingual=true };
		dummyProps.prop6 = { name="prop6", multilingual=true };

		var dummyObject = { meta={ name="app.preside-objects.myobject", tableName="test_table_name", multilingual=true, properties=dummyProps } };
		var multilingualObject = svc.createTranslationObject( "myobject", dummyObject );

		super.assertEquals( "_translation_test_table_name", multilingualObject.meta.tableName ?: "" );
	}

	function test07_createTranslationObject_shouldReturnAnObjectWithOnlyMultilingualPropertiesFromTheSourceObjectCarriedOver(){
		var svc        = _getService();
		var dummyProps = StructNew( "linked" );

		dummyProps.prop1 = { name="prop1", multilingual=true };
		dummyProps.prop2 = { name="prop2", multilingual=false };
		dummyProps.prop3 = { name="prop3" };
		dummyProps.prop4 = { name="prop4" };
		dummyProps.prop5 = { name="prop5", multilingual=true };
		dummyProps.prop6 = { name="prop6", multilingual=true };

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
			  name          = "_translation_source_record"
			, relationship  = "many-to-one"
			, relatedto     = "myobject"
			, required      = true
			, uniqueindexes = "translation|1"
			, indexes       = ""
			, ondelete      = "cascade"
			, onupdate      = "cascade"
			, generator     = "none"
			, control       = "none"
		}, actualProperties._translation_source_record );

		super.assertEquals( {
			  name          = "_translation_language"
			, relationship  = "many-to-one"
			, relatedto     = "multilingual_language"
			, required      = true
			, uniqueindexes = "translation|2"
			, indexes       = ""
			, ondelete      = "error"
			, onupdate      = "cascade"
			, generator     = "none"
			, control       = "none"
		}, actualProperties._translation_language );

		super.assertEquals( {
			  name          = "_translation_active"
			, required      = false
			, type          = "boolean"
			, dbtype        = "boolean"
			, default       = false
			, uniqueindexes = ""
			, indexes       = ""
			, relationship  = "none"
			, relatedto     = "none"
			, generator     = "none"
			, control       = "none"
			, maxLength     = 0
		}, actualProperties._translation_active );
	}

	function test09_createTranslationObject_shouldModifyDbFieldListBasedOnAdditionalFieldsAndMultilingualFields(){
		var svc        = _getService();
		var dummyProps = StructNew( "linked" );

		dummyProps.prop1 = { name="prop1", multilingual=true };
		dummyProps.prop2 = { name="prop2", multilingual=false };
		dummyProps.prop3 = { name="prop3" };
		dummyProps.prop4 = { name="prop4" };
		dummyProps.prop5 = { name="prop5", multilingual=true };
		dummyProps.prop6 = { name="prop6", multilingual=true };

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
			  name            = "_translations"
 			, relationship    = "one-to-many"
			, relatedto       = "_translation_myobject"
			, relationshipKey = "_translation_source_record"
			, required        = false
			, uniqueindexes   = ""
			, indexes         = ""
			, generator       = "none"
			, control         = "none"
		}, dummyObject.meta.properties._translations );
	}

	function test12_getTranslationObjectName_shouldReturnTheGivenObjectNamePrefixedWithTheTranslationObjectPrefix() {
		var svc = _getService();

		super.assertEquals( "_translation_my_object", svc.getTranslationObjectName( "my_object" ) );
	}

	function test13_selectTranslation_shouldReturnResultOfSelectDataCallWithTranslationFilters() {
		var svc = _getService();
		var objectName = "my_object";
		var id         = "someid";
		var language   = "somelanguage";
		var mockResult = QueryNew('id,label', 'varchar,varchar', [ ["idtest","labeltest"] ]);

		mockPresideObjectService.$( "selectData" ).$args(
			  selectFields = []
			, objectName   = "_translation_" & objectName
			, filter       = { _translation_source_record=id, _translation_language=language }
		).$results( mockResult );

		super.assertEquals( mockResult, svc.selectTranslation( objectName, id, language ) );
	}

// PRIVATE HELPERS
	private any function _getService() {
		mockRelationshipGuidance       = getMockbox().createEmptyMock( "preside.system.services.presideObjects.RelationshipGuidance" );
		mockSystemConfigurationService = getMockbox().createEmptyMock( "preside.system.services.configuration.SystemConfigurationService" );
		mockPresideObjectService       = getMockbox().createEmptyMock( "preside.system.services.presideObjects.PresideObjectService" );
		mockLanguageDao                = getMockbox().createStub();

		var svc = getMockbox().createMock( object=new preside.system.services.i18n.MultilingualPresideObjectService(
			 relationshipGuidance       = mockRelationshipGuidance
		) );

		svc.$( "$getPresideObject" ).$args( "multilingual_language" ).$results( mockLanguageDao );
		svc.$( "$getPresideObjectService", mockPresideObjectService );

		return svc;
	}
}