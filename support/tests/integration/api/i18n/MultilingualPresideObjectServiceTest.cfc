component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run(){
		describe( "listLanguages()", function(){
			it( "should pull languages from settings and merge with data from language preside object", function(){
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

				expect( svc.listLanguages() ).toBe( expectedResult );
			} );

			it( "should not include default language when flag to exclude default is set to true", function(){
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

				expect( svc.listLanguages( includeDefault=false ) ).toBe( expectedResult );
			} );
		} );

		describe( "getTranslationStatus()", function(){
			it( "should return statuses of translations for each non default language by looking up translation records and their draft statuses", function(){
				var svc           = _getService();
				var objectName    = "someobject";
				var recordId      = CreateUUId();
				var mockLanguages = [{id="lang_1"},{id="lang_2"},{id="lang_3"},{id="lang_4"}];
				var mockDbResult  = QueryNew('_translation_language,_version_is_draft,_version_has_drafts', "varchar,bit,bit", [
					 [ "lang_3", 0, 0 ]
					,[ "lang_1", 1, 1 ]
					,[ "lang_4", 0, 1 ]
				]);
				var expectedResult = [
					  { id="lang_1", status="inprogress" }
					, { id="lang_2", status="notstarted" }
					, { id="lang_3", status="active" }
					, { id="lang_4", status="inprogress" }
				];

				svc.$( "listLanguages" ).$args( includeDefault=false ).$results( mockLanguages );
				mockPresideObjectService.$( "objectIsVersioned" ).$args( objectName ).$results( true )
				mockPresideObjectService.$( "selectData" ).$args(
					  selectFields       = [ "_translation_language", "_version_is_draft", "_version_has_drafts" ]
					, objectName         = "_translation_" & objectName
					, filter             = { _translation_source_record=recordId }
					, allowDraftVersions = true
				).$results( mockDbResult );

				expect( svc.getTranslationStatus( objectName, recordId ) ).toBe( expectedResult );
			} );

			it( "should return statuses of translations for each non default language by looking up translation records existance / non-existance when version history not enabled on the object", function(){
				var svc           = _getService();
				var objectName    = "someobject";
				var recordId      = CreateUUId();
				var mockLanguages = [{id="lang_1"},{id="lang_2"},{id="lang_3"},{id="lang_4"}];
				var mockDbResult  = QueryNew('_translation_language', "varchar", [
					 [ "lang_3" ]
					,[ "lang_1" ]
					,[ "lang_4" ]
				]);
				var expectedResult = [
					  { id="lang_1", status="active" }
					, { id="lang_2", status="notstarted" }
					, { id="lang_3", status="active" }
					, { id="lang_4", status="active" }
				];

				svc.$( "listLanguages" ).$args( includeDefault=false ).$results( mockLanguages );
				mockPresideObjectService.$( "objectIsVersioned" ).$args( objectName ).$results( false )
				mockPresideObjectService.$( "selectData" ).$args(
					  selectFields       = [ "_translation_language" ]
					, objectName         = "_translation_" & objectName
					, filter             = { _translation_source_record=recordId }
					, allowDraftVersions = true
				).$results( mockDbResult );

				expect( svc.getTranslationStatus( objectName, recordId ) ).toBe( expectedResult );
			} );
		} );

		describe( "getLanguage()", function(){
			it( "should return an empty struct when the language is not an actively translatable language", function(){
				var svc = _getService();

				svc.$( "listLanguages", [{id="id-1", name="French", default=true }] );

				expect( svc.getLanguage( "id-5" ) ).toBeEmpty();
			} );

			it( "should return details of actively translatable language", function(){
				var svc = _getService();
				var languages = [{id="id-1", name="French", default=true }, {id="id-2", name="English", default=false}]

				svc.$( "listLanguages", languages );

				expect( svc.getLanguage( "id-2" ) ).toBe( languages[ 2 ] );
			} );
		} );

		describe( "createTranslationObject()", function(){
			it( "should return an object who's table name is the source object prepended with ""_translation""", function(){
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

				expect( multilingualObject.meta.tableName ?: "" ).toBe( "_translation_test_table_name" );

			} );

			it( "should return an object with only multilingual properties from the source object carried over", function(){
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

				expect( actualProperties.keyExists( "prop1") ).toBeTrue();
				expect( actualProperties.keyExists( "prop5") ).toBeTrue();
				expect( actualProperties.keyExists( "prop6") ).toBeTrue();
				expect( actualProperties.keyExists( "prop2") ).toBeFalse();
				expect( actualProperties.keyExists( "prop3") ).toBeFalse();
				expect( actualProperties.keyExists( "prop4") ).toBeFalse();
			} );

			it( "should add fields for relating to source record and defining language", function(){
				var svc                = _getService();
				var dummyObject        = { meta={ name="app.preside-objects.myobject", tableName="test_table_name", multilingual=true, properties={} } };
				var multilingualObject = svc.createTranslationObject( "myobject", dummyObject );
				var actualProperties   = multilingualObject.meta.properties ?: {};

				expect( actualProperties.keyExists( "_translation_source_record" ) ).toBeTrue();
				expect( actualProperties.keyExists( "_translation_language"      ) ).toBeTrue();

				expect( actualProperties._translation_source_record ).toBe( {
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
				} );

				expect( actualProperties._translation_language ).toBe( {
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
				} );
			} );

			it( "should modify db field list based on additional fields and multilingual fields", function(){
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

				expect( multilingualObject.meta.dbFieldList ?: "" ).toBe( "prop1,prop6,_translation_source_record,_translation_language"  );
			} );

			it( "should add unique index to the object definition", function(){
				var svc                = _getService();
				var dummyObject        = { meta={ name="app.preside-objects.myobject", tableName="test_table_name", multilingual=true, properties={} } };
				var multilingualObject = svc.createTranslationObject( "myobject", dummyObject );

				expect( multilingualObject.meta.indexes[ "ux_translation_myobject_translation" ] ?: {} ).toBe( { unique=true, fields="_translation_source_record,_translation_language" } );
			} );
		} );

		describe( "decorateMultilingualObject()", function(){
			it( "should add oneToMany property to source object to aid with translation lookup queries", function(){
				var svc                = _getService();
				var dummyObject        = { meta={ name="app.preside-objects.myobject", tableName="test_table_name", multilingual=true, properties={} } };

				svc.decorateMultilingualObject( "myobject", dummyObject );

				expect( dummyObject.meta.properties.keyExists( "_translations" ) ).toBeTrue();
				expect( dummyObject.meta.properties._translations ).toBe( {
					  name            = "_translations"
		 			, relationship    = "one-to-many"
					, relatedto       = "_translation_myobject"
					, relationshipKey = "_translation_source_record"
					, required        = false
					, uniqueindexes   = ""
					, indexes         = ""
					, generator       = "none"
					, control         = "none"
				} );
			} );
		} );

		describe( "getTranslationObjectName()", function(){
			it( "should return the given object name prefixed with the translation object prefix", function(){
				var svc = _getService();

				expect( svc.getTranslationObjectName( "my_object" ) ).toBe( "_translation_my_object" );
			} );
		} );

		describe( "selectTranslation()", function(){
			it( "should return result of selectData() call with translation filters", function(){
				var svc = _getService();
				var objectName = "my_object";
				var id         = "someid";
				var language   = "somelanguage";
				var mockResult = QueryNew('id,label', 'varchar,varchar', [ ["idtest","labeltest"] ]);

				mockPresideObjectService.$( "selectData" ).$args(
					  selectFields       = []
					, objectName         = "_translation_" & objectName
					, filter             = { _translation_source_record=id, _translation_language=language }
					, allowDraftVersions = true
				).$results( mockResult );

				expect( mockResult, svc.selectTranslation( objectName, id, language ) );
			} );
		} );

	}

	private any function _getService() {
		mockRelationshipGuidance       = getMockbox().createEmptyMock( "preside.system.services.presideObjects.RelationshipGuidance" );
		mockSystemConfigurationService = getMockbox().createEmptyMock( "preside.system.services.configuration.SystemConfigurationService" );
		mockPresideObjectService       = getMockbox().createEmptyMock( "preside.system.services.presideObjects.PresideObjectService" );
		mockCookieService              = getMockbox().createEmptyMock( "preside.system.services.cfmlscopes.CookieService" );
		mockLanguageDao                = getMockbox().createStub();

		var svc = createMock( object=new preside.system.services.i18n.MultilingualPresideObjectService(
			  relationshipGuidance = mockRelationshipGuidance
			, cookieService        = mockCookieService
		) );

		svc.$( "$getPresideObject" ).$args( "multilingual_language" ).$results( mockLanguageDao );
		svc.$( "$getPresideObjectService", mockPresideObjectService );

		return svc;
	}

}