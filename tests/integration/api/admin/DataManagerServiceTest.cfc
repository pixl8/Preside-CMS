component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "getGroupedObjects()", function(){
			it( "should return objects in their configured groups", function(){
				var dataManagerService = _getService();
				var expected = [
					  { title="Another group", description="Another description", icon="another-icon-class", objects=[
						  { id="object4", title="Object 4", iconClass="fa-object-4" }
					  ] }
					, { title="Some group", description="Some description", icon="an-icon-class", objects=[
						  { id="object1", title="Object 1", iconClass="fa-object-1" }
						, { id="object2", title="Object 2", iconClass="fa-object-2" }
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
						  { id="object1", title="Object 1", iconClass="fa-object-1" }
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
						  { id="object4", title="Object 4", iconClass="fa-object-4" }
					  ] }
					, { title="Some group", description="Some description", icon="an-icon-class", objects=[
						  { id="object1", title="Object 1", iconClass="fa-object-1" }
						, { id="object2", title="Object 2", iconClass="fa-object-2" }
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
						  { id="object4", title="Object 4", iconClass="fa-object-4" }
						, { id="object6", title="Object 6", iconClass="fa-object-6" }
					  ] }
					, { title="Some group", description="Some description", icon="an-icon-class", objects=[
						  { id="object1", title="Object 1", iconClass="fa-object-1" }
						, { id="object2", title="Object 2", iconClass="fa-object-2" }
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
				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = "object4"
					, attributeName = "noDateCreated"
				).$results( false );
				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = "object4"
					, attributeName = "noDateModified"
				).$results( false );

				expect( dataManagerService.listGridFields( "object4" ) ).toBe( ["field1","field2","field3"] );
			} );
		} );

		describe( "defaultGridFields()", function(){
			it( "should return default grid fields for object", function(){
				var dataManagerService = _getService();

				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = "object4"
					, attributeName = "labelfield"
					, defaultValue  = "label"
				).$results( "testlabelfield" );
				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = "object4"
					, attributeName = "noDateCreated"
				).$results( false );
				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = "object4"
					, attributeName = "noDateModified"
				).$results( false );

				expect( dataManagerService.defaultGridFields( "object4" ) ).toBe( ["testlabelfield","datecreated","datemodified"] );
			} );

			it( "should return default grid fields for object without modified and created dates if excluded", function(){
				var dataManagerService = _getService();

				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = "object4"
					, attributeName = "labelfield"
					, defaultValue  = "label"
				).$results( "testlabelfield" );
				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = "object4"
					, attributeName = "noDateCreated"
				).$results( true );
				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = "object4"
					, attributeName = "noDateModified"
				).$results( true );

				expect( dataManagerService.defaultGridFields( "object4" ) ).toBe( ["testlabelfield"] );
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

		describe( "sanitizeOrderBy()", function(){
			it( "should keep a real field and an asc or desc direction", function(){
				var dataManagerService = _getService();

				_stubOrderByFields( [ "known_as" ] );

				expect( dataManagerService.sanitizeOrderBy( objectName="security_user", orderBy="known_as desc", fallback="label" ) ).toBe( "known_as desc" );
			} );

			it( "should fall back when the direction is not asc or desc", function(){
				var dataManagerService = _getService();

				_stubOrderByFields( [ "known_as" ] );

				expect( dataManagerService.sanitizeOrderBy( objectName="security_user", orderBy="known_as not_a_direction", fallback="label" ) ).toBe( "label" );
			} );

			it( "should keep the literal label sort without a matching property", function(){
				var dataManagerService = _getService();

				_stubOrderByFields( [] );

				expect( dataManagerService.sanitizeOrderBy( objectName="security_user", orderBy="label", fallback="id" ) ).toBe( "label" );
			} );

			it( "should fall back when the sort is a function expression", function(){
				var dataManagerService = _getService();

				_stubOrderByFields( [ "id", "known_as" ] );

				expect( dataManagerService.sanitizeOrderBy(
					  objectName = "security_user"
					, orderBy    = "field( id, 'c', 'a', 'b' )"
					, fallback   = "label"
				) ).toBe( "label" );
				expect( dataManagerService.sanitizeOrderBy(
					  objectName = "security_user"
					, orderBy    = "max( known_as ) desc"
					, fallback   = "label"
				) ).toBe( "label" );
			} );

			it( "should drop a clause that is not an object field", function(){
				var dataManagerService = _getService();

				_stubOrderByFields( [ "label" ] );

				expect( dataManagerService.sanitizeOrderBy(
					  objectName = "crm_organisation"
					, orderBy    = "label asc, label;select"
					, fallback   = ""
				) ).toBe( "label asc" );
			} );
		} );

		describe( "_prependPreferredValueSort()", function(){
			it( "should escape a quote in the preferred value", function(){
				var dataManagerService = _getService();

				_stubOrderByFields( [ "id" ] );
				makePublic( dataManagerService, "_prependPreferredValueSort" );

				expect( dataManagerService._prependPreferredValueSort(
					  objectName  = "security_user"
					, orderBy     = "label"
					, preferField = "id"
					, preferValue = "o'brien"
				) ).toBe( "CASE WHEN security_user.id = 'o''brien' THEN 0 ELSE 1 END, label" );
			} );

			it( "should ignore a preferred value that contains a backslash", function(){
				var dataManagerService = _getService();

				_stubOrderByFields( [ "id" ] );
				makePublic( dataManagerService, "_prependPreferredValueSort" );

				expect( dataManagerService._prependPreferredValueSort(
					  objectName  = "security_user"
					, orderBy     = "label"
					, preferField = "id"
					, preferValue = "a" & Chr( 92 ) & "b"
				) ).toBe( "label" );
			} );

			it( "should ignore a preferred field that is not on the object", function(){
				var dataManagerService = _getService();

				_stubOrderByFields( [ "id" ] );
				makePublic( dataManagerService, "_prependPreferredValueSort" );

				expect( dataManagerService._prependPreferredValueSort(
					  objectName  = "security_user"
					, orderBy     = "label"
					, preferField = "not_a_field"
					, preferValue = "x"
				) ).toBe( "label" );
			} );
		} );
	}

	private void function _stubOrderByFields( required array fieldNames ) {
		var allowedFields = arguments.fieldNames;

		mockPoService.$( "fieldExists" ).$callback( function(){
			var fieldName = arguments.fieldName ?: ( arguments[ 2 ] ?: "" );

			return allowedFields.findNoCase( fieldName ) > 0;
		} );
		mockPoService.$( "getObjectProperty" ).$callback( function(){
			var fieldName = arguments.propertyName ?: ( arguments[ 2 ] ?: "" );

			if ( allowedFields.findNoCase( fieldName ) ) {
				return { name=fieldName };
			}

			throw( type="preside.object.property.not.found", message="missing field" );
		} );
	}

	private any function _getService() {
		mockPoService            = createEmptyMock( "preside.system.services.presideObjects.PresideObjectService" );
		contentRenderer          = createEmptyMock( "preside.system.services.rendering.ContentRenderer" );
		labelRendererService     = createEmptyMock( "preside.system.services.rendering.LabelRendererService" );
		mockPermissionService    = createEmptyMock( "preside.system.services.security.PermissionService" );
		mockI18nPlugin           = createEmptyMock( "preside.system.services.i18n.i18n" );
		mockSiteService          = createEmptyMock( "preside.system.services.siteTree.SiteService" );
		mockRelationshipGuidance = createEmptyMock( "preside.system.services.presideObjects.RelationshipGuidance" );
		mockCustomizationService = createEmptyMock( "preside.system.services.admin.DataManagerCustomizationService" );
		mockCloningService       = createEmptyMock( "preside.system.services.presideObjects.PresideObjectCloningService" );
		mockMultilingualService  = createEmptyMock( "preside.system.services.i18n.MultilingualPresideObjectService" );

		_setupMockObjectMeta();

		return new preside.system.services.admin.DataManagerService(
			  presideObjectService = mockPoService
			, i18nPlugin           = mockI18nPlugin
			, contentRenderer      = contentRenderer
			, labelRendererService = labelRendererService
			, permissionService    = mockPermissionService
			, siteService          = mockSiteService
			, relationshipGuidance = mockRelationshipGuidance
			, customizationService = mockCustomizationService
			, cloningService       = mockCloningService
			, multilingualService  = mockMultilingualService
		);
	}

	private void function _setupMockObjectMeta() output=false {
		mockPoService.$( "listObjects", [ "object1", "object2", "object3", "object4", "object5" ] );

		mockPoService.$( "getObjectAttribute" ).$args( objectName="object1", attributeName="datamanagergroup" ).$results( "somegroup" );
		mockPoService.$( "getObjectAttribute" ).$args( objectName="object2", attributeName="datamanagergroup" ).$results( "somegroup" );
		mockPoService.$( "getObjectAttribute" ).$args( objectName="object3", attributeName="datamanagergroup" ).$results( "" );
		mockPoService.$( "getObjectAttribute" ).$args( objectName="object3", attributeName="datamanagerEnabled" ).$results( "" );
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

		mockI18nPlugin.$( "translateResource" ).$args( uri="preside-objects.object1:iconClass", defaultValue="fa-database" ).$results( "fa-object-1" );
		mockI18nPlugin.$( "translateResource" ).$args( uri="preside-objects.object2:iconClass", defaultValue="fa-database" ).$results( "fa-object-2" );
		mockI18nPlugin.$( "translateResource" ).$args( uri="preside-objects.object3:iconClass", defaultValue="fa-database" ).$results( "fa-object-3" );
		mockI18nPlugin.$( "translateResource" ).$args( uri="preside-objects.object4:iconClass", defaultValue="fa-database" ).$results( "fa-object-4" );
		mockI18nPlugin.$( "translateResource" ).$args( uri="preside-objects.object5:iconClass", defaultValue="fa-database" ).$results( "fa-object-5" );
		mockI18nPlugin.$( "translateResource" ).$args( uri="preside-objects.object6:iconClass", defaultValue="fa-database" ).$results( "fa-object-6" );



		mockSiteService.$( "getActiveSiteTemplate", "" );
	}
}