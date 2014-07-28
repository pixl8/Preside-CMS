component extends="tests.resources.HelperObjects.PresideTestCase" output=false {

// SETUP, TEARDOWN, etc
	function setup() output=false {
		mockPoService         = getMockBox().createEmptyMock( "preside.system.services.presideObjects.PresideObjectService" );
		contentRenderer       = getMockBox().createEmptyMock( "preside.system.services.rendering.ContentRenderer" );
		mockPermissionService = getMockBox().createEmptyMock( "preside.system.services.security.PermissionService" );
		mockI18nPlugin        = getMockBox().createEmptyMock( "preside.system.coldboxModifications.plugins.i18n" );
		mockSiteService       = getMockBox().createEmptyMock( "preside.system.services.siteTree.SiteService" );

		_setupMockObjectMeta();

		dataManagerService = new preside.system.services.admin.DataManagerService(
			  presideObjectService = mockPoService
			, i18nPlugin           = mockI18nPlugin
			, contentRenderer      = contentRenderer
			, permissionService    = mockPermissionService
			, siteService          = mockSiteService
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
		var groups   = "";

		mockPermissionService.$( "hasPermission", true );

		groups = dataManagerService.getGroupedObjects();

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

	function test05_getGroupedObjects_shouldNotContainObjectsToWhichTheLoggedInUserDoesNotHaveNavigationPermissions() output=false {
		var expected = [
			  { title="Some group", description="Some description", icon="an-icon-class", objects=[
				  { id="object1", title="Object 1" }
			  ] }
		];
		var groups   = "";

		mockPermissionService.$( "hasPermission" ).$args(
			  permissionKey = "datamanager.navigate"
			, context       = "datamanager"
			, contextKeys   = [ "object1" ]
		).$results( true );
		mockPermissionService.$( "hasPermission" ).$args(
			  permissionKey = "datamanager.navigate"
			, context       = "datamanager"
			, contextKeys   = [ "object2" ]
		).$results( false );
		mockPermissionService.$( "hasPermission" ).$args(
			  permissionKey = "datamanager.navigate"
			, context       = "datamanager"
			, contextKeys   = [ "object4" ]
		).$results( false );

		groups = dataManagerService.getGroupedObjects();

		super.assertEquals( expected, groups );
	}

	function test06_getGroupedObjects_shouldNotReturnObjectsThatAreExclusiveToASiteTemplateThatIsNotTheActiveTemplate() output=false {
		var groups   = "";
		var expected = [
			  { title="Another group", description="Another description", icon="another-icon-class", objects=[
				  { id="object4", title="Object 4" }
			  ] }
			, { title="Some group", description="Some description", icon="an-icon-class", objects=[
				  { id="object1", title="Object 1" }
				, { id="object2", title="Object 2" }
			  ] }
		];

		mockPermissionService.$( "hasPermission", true );
		mockPoService.$( "listObjects", [ "object1", "object2", "object3", "object4", "object5", "object6" ] );
		mockPoService.$( "getObjectAttribute" ).$args( objectName="object6", attributeName="siteTemplates"   , defaultValue="*" ).$results( "sometemplate" );
		mockPoService.$( "getObjectAttribute" ).$args( objectName="object6", attributeName="datamanagergroup", defaultValue="" ).$results( "anothergroup" );
		mockI18nPlugin.$( "translateResource" ).$args( uri="preside-objects.object6:title" ).$results( "Object 6" );

		mockSiteService.$( "getActiveSiteTemplate", "someotherteplate" );

		groups = dataManagerService.getGroupedObjects();

		super.assertEquals( expected, groups );
	}

	function test07_getGroupedObjects_shouldReturnObjectsThatAreExclusiveToTheActiveSiteTemplate() output=false {
		var groups   = "";
		var expected = [
			  { title="Another group", description="Another description", icon="another-icon-class", objects=[
				  { id="object4", title="Object 4" }
				, { id="object6", title="Object 6" }
			  ] }
			, { title="Some group", description="Some description", icon="an-icon-class", objects=[
				  { id="object1", title="Object 1" }
				, { id="object2", title="Object 2" }
			  ] }
		];

		mockPermissionService.$( "hasPermission", true );
		mockPoService.$( "listObjects", [ "object1", "object2", "object3", "object4", "object5", "object6" ] );
		mockPoService.$( "getObjectAttribute" ).$args( objectName="object6", attributeName="siteTemplates"   , defaultValue="*" ).$results( "sometemplate" );
		mockPoService.$( "getObjectAttribute" ).$args( objectName="object6", attributeName="datamanagergroup", defaultValue="" ).$results( "anothergroup" );
		mockI18nPlugin.$( "translateResource" ).$args( uri="preside-objects.object6:title" ).$results( "Object 6" );

		mockSiteService.$( "getActiveSiteTemplate", "sometemplate" );

		groups = dataManagerService.getGroupedObjects();

		super.assertEquals( expected, groups );
	}


// PRIVATE UTILITY METHODS
	private void function _setupMockObjectMeta() output=false {
		mockPoService.$( "listObjects", [ "object1", "object2", "object3", "object4", "object5" ] );

		mockPoService.$( "getObjectAttribute" ).$args( objectName="object1", attributeName="datamanagergroup" ).$results( "somegroup" );
		mockPoService.$( "getObjectAttribute" ).$args( objectName="object2", attributeName="datamanagergroup" ).$results( "somegroup" );
		mockPoService.$( "getObjectAttribute" ).$args( objectName="object3", attributeName="datamanagergroup" ).$results( "" );
		mockPoService.$( "getObjectAttribute" ).$args( objectName="object4", attributeName="datamanagergroup" ).$results( "anothergroup" );
		mockPoService.$( "getObjectAttribute" ).$args( objectName="object5", attributeName="datamanagergroup" ).$results( "" );

		mockPoService.$( "getObjectAttribute" ).$args( objectName="object1", attributeName="siteTemplates", defaultValue="*" ).$results( "*" );
		mockPoService.$( "getObjectAttribute" ).$args( objectName="object2", attributeName="siteTemplates", defaultValue="*" ).$results( "*" );
		mockPoService.$( "getObjectAttribute" ).$args( objectName="object3", attributeName="siteTemplates", defaultValue="*" ).$results( "*" );
		mockPoService.$( "getObjectAttribute" ).$args( objectName="object4", attributeName="siteTemplates", defaultValue="*" ).$results( "*" );
		mockPoService.$( "getObjectAttribute" ).$args( objectName="object5", attributeName="siteTemplates", defaultValue="*" ).$results( "*" );

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

		mockSiteService.$( "getActiveSiteTemplate", "" );
	}
}