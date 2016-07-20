component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "getGroupedObjects()", function(){
			it( "should return objects in their configured groups", function(){
				var dataManagerService = _getService();
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

				expect( groups ).toBe( expected );
			} );

			it( "should not contain object to which the logged in user does not have navigation permissions", function(){
				var dataManagerService = _getService();
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

				expect( groups ).toBe( expected );
			} );

			it( "should not return objects that are exclusive to a site template that is not the active template", function(){
				var dataManagerService = _getService();
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

				expect( groups ).toBe( expected );
			} );

			it( "should return objects that are exclusive to the active site template", function(){
				var dataManagerService = _getService();
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

				expect( groups ).toBe( expected );
			} );
		} );

		describe( "isObjectAvailableInDataManager()", function(){
			it( "should return fals when object does not belong to a group", function(){
				var dataManagerService = _getService();

				expect( dataManagerService.isObjectAvailableInDataManager( "object3" ) ).toBeFalse();
			} );

			it( "should return true when object belongs to a group", function(){
				var dataManagerService = _getService();

				expect( dataManagerService.isObjectAvailableInDataManager( "object2" ) ).toBeTrue();
			} );

		} );

		describe( "listGridFields()", function(){
			it( "should return configured grid fields for object", function(){
				var dataManagerService = _getService();

				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = "object4"
					, attributeName = "labelfield"
					, defaultValue  = "label"
				).$results( "testlabelfield" );
				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = "object4"
					, attributeName = "datamanagerGridFields"
					, defaultValue  = "testlabelfield,datecreated,datemodified"
				).$results( "field1,field2,field3" );

				expect( dataManagerService.listGridFields( "object4" ) ).toBe( ["field1","field2","field3"] );
			} );
		} );

		describe( "areDraftsEnabledForObject()", function(){
			it( "should return false when versioning is not enabled for the object", function(){
				var dataManagerService = _getService();
				var objectName         = "test_object";

				mockPoService.$( "objectIsVersioned" ).$args( objectName ).$results( false );

				expect( dataManagerService.areDraftsEnabledForObject( objectName ) ).toBeFalse();
			} );

			it( "should return false when versioning is enabled but drafts attribute not set on the object", function(){
				var dataManagerService = _getService();
				var objectName         = "test_object";

				mockPoService.$( "objectIsVersioned" ).$args( objectName ).$results( true );
				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = objectName
					, attributeName = "datamanagerAllowDrafts"
					, defaultValue  = ""
				).$results( "" );

				expect( dataManagerService.areDraftsEnabledForObject( objectName ) ).toBeFalse();
			} );

			it( "should return true when versioning is enabled and 'datamanagerAllowDrafts' attribute set to true on the object", function(){
				var dataManagerService = _getService();
				var objectName         = "test_object";

				mockPoService.$( "objectIsVersioned" ).$args( objectName ).$results( true );
				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = objectName
					, attributeName = "datamanagerAllowDrafts"
					, defaultValue  = ""
				).$results( true );

				expect( dataManagerService.areDraftsEnabledForObject( objectName ) ).toBeTrue();
			} );
		} );
	}

	private any function _getService() {
		mockPoService         = createEmptyMock( "preside.system.services.presideObjects.PresideObjectService" );
		contentRenderer       = createEmptyMock( "preside.system.services.rendering.ContentRenderer" );
		mockPermissionService = createEmptyMock( "preside.system.services.security.PermissionService" );
		mockI18nPlugin        = createEmptyMock( "preside.system.coldboxModifications.plugins.i18n" );
		mockSiteService       = createEmptyMock( "preside.system.services.siteTree.SiteService" );

		_setupMockObjectMeta();

		return new preside.system.services.admin.DataManagerService(
			  presideObjectService = mockPoService
			, i18nPlugin           = mockI18nPlugin
			, contentRenderer      = contentRenderer
			, permissionService    = mockPermissionService
			, siteService          = mockSiteService
		);
	}

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