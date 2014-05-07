component extends="tests.resources.HelperObjects.PresideTestCase" output=false {

// SETUP, TEARDOWN, etc
	function setup() output=false {
		mockPoService   = getMockBox().createEmptyMock( "preside.system.api.presideObjects.PresideObjectService" );
		contentRenderer = getMockBox().createEmptyMock( "preside.system.api.rendering.ContentRenderer" );
		mockI18nPlugin  = getMockBox().createEmptyMock( "preside.system.coldboxModifications.plugins.i18n" );

		_setupMockObjectMeta();

		dataManagerService = new preside.system.api.admin.DataManagerService(
			  presideObjectService = mockPoService
			, logger               = _getTestLogger()
			, i18nPlugin           = mockI18nPlugin
			, contentRenderer      = contentRenderer
		);
	}

// TESTS
	function test01_getGroupedObjects_shouldReturnObjectsInTheirConfiguredGroups() output=false {
		var expected = [
			  { title="Another group", description="Another description", icon="another-icon-class", objects=[
				  { id="object4", title="Object 4" }
			  ] }
			, { title="Some group", description="Some description", icon="an-icon-class", objects=[
				  { id="object1", title="Object 1" }
				, { id="object2", title="Object 2" }
			  ] }
		];
		var groups   = dataManagerService.getGroupedObjects();

		super.assertEquals( expected, groups );
	}

	function test02_isObjectAvailableInDataManager_shouldReturnFalse_whenObjectDoesNotBelongToAGroup() output=false {
		super.assertFalse( dataManagerService.isObjectAvailableInDataManager( "object3" ) );
	}

	function test03_isObjectAvailableInDataManager_shouldReturnTrue_whenObjectBelongsToAGroup() output=false {
		super.assert( dataManagerService.isObjectAvailableInDataManager( "object2" ) );
	}

	function test04_listGridFields_shouldReturnConfiguredGridFieldsForObject() output=false {
		mockPoService.$( "getObjectAttribute" ).$args(
			  objectName    = "object4"
			, attributeName = "datamanagerGridFields"
			, defaultValue  = "label,datecreated,datemodified"
		).$results( "field1,field2,field3" );

		super.assertEquals( ["field1","field2","field3"], dataManagerService.listGridFields( "object4" ) );
	}


// PRIVATE UTILITY METHODS
	private void function _setupMockObjectMeta() output=false {
		mockPoService.$( "listObjects", [ "object1", "object2", "object3", "object4", "object5" ] );

		mockPoService.$( "getObjectAttribute" ).$args( objectName="object1", attributeName="datamanagergroup" ).$results( "somegroup" );
		mockPoService.$( "getObjectAttribute" ).$args( objectName="object2", attributeName="datamanagergroup" ).$results( "somegroup" );
		mockPoService.$( "getObjectAttribute" ).$args( objectName="object3", attributeName="datamanagergroup" ).$results( "" );
		mockPoService.$( "getObjectAttribute" ).$args( objectName="object4", attributeName="datamanagergroup" ).$results( "anothergroup" );
		mockPoService.$( "getObjectAttribute" ).$args( objectName="object5", attributeName="datamanagergroup" ).$results( "" );

		mockI18nPlugin.$( "translateResource" ).$args( uri="preside-objects.groups.somegroup:title" ).$results( "Some group" );
		mockI18nPlugin.$( "translateResource" ).$args( uri="preside-objects.groups.somegroup:description" ).$results( "Some description" );
		mockI18nPlugin.$( "translateResource" ).$args( uri="preside-objects.groups.somegroup:iconclass" ).$results( "an-icon-class" );
		mockI18nPlugin.$( "translateResource" ).$args( uri="preside-objects.groups.anothergroup:title" ).$results( "Another group" );
		mockI18nPlugin.$( "translateResource" ).$args( uri="preside-objects.groups.anothergroup:description" ).$results( "Another description" );
		mockI18nPlugin.$( "translateResource" ).$args( uri="preside-objects.groups.anothergroup:iconclass" ).$results( "another-icon-class" );

		mockI18nPlugin.$( "translateResource" ).$args( uri="preside-objects.object1:title" ).$results( "Object 1" );
		mockI18nPlugin.$( "translateResource" ).$args( uri="preside-objects.object2:title" ).$results( "Object 2" );
		mockI18nPlugin.$( "translateResource" ).$args( uri="preside-objects.object3:title" ).$results( "Object 3" );
		mockI18nPlugin.$( "translateResource" ).$args( uri="preside-objects.object4:title" ).$results( "Object 4" );
		mockI18nPlugin.$( "translateResource" ).$args( uri="preside-objects.object5:title" ).$results( "Object 5" );
	}
}