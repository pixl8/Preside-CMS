component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "getRendererForField()", function(){
			it( "should return defined 'adminRenderer' on the property when defined", function(){
				var service = _getService();

				mockPoService.$( "getObjectProperty" ).$args( "testobject", "testprop" ).$results( { adminRenderer="whatever", renderer="frontend", type="string", dbtype="varchar", relationship="none" } );
				expect( service.getRendererForField( "testobject", "testprop" ) ).toBe( "whatever" );
			} );

			it( "should return defined 'renderer' on the property when defined and no 'adminRenderer' defined", function(){
				var service = _getService();

				mockPoService.$( "getObjectProperty" ).$args( "testobject", "testprop" ).$results( { renderer="alsdkjf", type="string", dbtype="varchar", relationship="none" } );
				expect( service.getRendererForField( "testobject", "testprop" ) ).toBe( "alsdkjf" );
			} );

			it( "should return sensible defaults when properties do not speficy an admin renderer or default renderer", function(){
				var service  = _getService();
				var propName = "";

				propName = "property_" & CreateUUId();
				mockPoService.$( "getObjectProperty" ).$args( "testobject", propName ).$results( { type="string", dbtype="varchar", relationship="none" } );
				expect( service.getRendererForField( "testobject", propName ) ).toBe( "plaintext" );

				propName = "property_" & CreateUUId();
				mockPoService.$( "getObjectProperty" ).$args( "testobject2", propName ).$results( { type="string", dbtype="text", relationship="none" } );
				expect( service.getRendererForField( "testobject2", propName ) ).toBe( "richeditor" );

				propName = "property_" & CreateUUId();
				mockPoService.$( "getObjectProperty" ).$args( "testobject2", propName ).$results( { type="string", dbtype="longtext", relationship="none" } );
				expect( service.getRendererForField( "testobject2", propName ) ).toBe( "richeditor" );

				propName = "property_" & CreateUUId();
				mockPoService.$( "getObjectProperty" ).$args( "testobject2", propName ).$results( { type="string", dbtype="mediumtext", relationship="none" } );
				expect( service.getRendererForField( "testobject2", propName ) ).toBe( "richeditor" );

				propName = "property_" & CreateUUId();
				mockPoService.$( "getObjectProperty" ).$args( "testobject", propName ).$results( { type="date", dbtype="datetime", relationship="none" } );
				expect( service.getRendererForField( "testobject", propName ) ).toBe( "datetime" );

				propName = "property_" & CreateUUId();
				mockPoService.$( "getObjectProperty" ).$args( "testobject", propName ).$results( { type="date", dbtype="timestamp", relationship="none" } );
				expect( service.getRendererForField( "testobject", propName ) ).toBe( "datetime" );

				propName = "property_" & CreateUUId();
				mockPoService.$( "getObjectProperty" ).$args( "testobject", propName ).$results( { type="date", dbtype="date", relationship="none" } );
				expect( service.getRendererForField( "testobject", propName ) ).toBe( "date" );

				propName = "property_" & CreateUUId();
				mockPoService.$( "getObjectProperty" ).$args( "testobject", propName ).$results( { type="boolean", dbtype="boolean", relationship="none" } );
				expect( service.getRendererForField( "testobject", propName ) ).toBe( "boolean" );

				propName = "property_" & CreateUUId();
				mockPoService.$( "getObjectProperty" ).$args( "testobject", propName ).$results( { type="boolean", dbtype="bit", relationship="none" } );
				expect( service.getRendererForField( "testobject", propName ) ).toBe( "boolean" );

				propName = "property_" & CreateUUId();
				mockPoService.$( "getObjectProperty" ).$args( "testobject", propName ).$results( { relationship="many-to-one", relatedto="something" } );
				expect( service.getRendererForField( "testobject", propName ) ).toBe( "manyToOne" );

				propName = "property_" & CreateUUId();
				mockPoService.$( "getObjectProperty" ).$args( "testobject", propName ).$results( { relationship="many-to-one", relatedto="asset" } );
				expect( service.getRendererForField( "testobject", propName ) ).toBe( "asset" );

				propName = "property_" & CreateUUId();
				mockPoService.$( "getObjectProperty" ).$args( "testobject", propName ).$results( { relationship="many-to-one", relatedto="link" } );
				expect( service.getRendererForField( "testobject", propName ) ).toBe( "link" );

				propName = "property_" & CreateUUId();
				mockPoService.$( "getObjectProperty" ).$args( "testobject", propName ).$results( { relationship="one-to-many", relatedto="blah" } );
				expect( service.getRendererForField( "testobject", propName ) ).toBe( "objectRelatedRecords" );

				propName = "property_" & CreateUUId();
				mockPoService.$( "getObjectProperty" ).$args( "testobject", propName ).$results( { relationship="many-to-many", relatedto="blah" } );
				expect( service.getRendererForField( "testobject", propName ) ).toBe( "objectRelatedRecords" );
			} );
		} );

		describe( "renderField()", function() {
			it( "should call the content renderer for the field, passing in objectName, propertyName and recordId as additional args to the renderer", function(){
				var service      = _getService();
				var value        = CreateUUId();
				var recordId     = CreateUUId();
				var objectName   = "blah" & CreateUUId();
				var propertyName = "fubar" & CreateUUId();
				var renderer     = CreateUUId();
				var rendered     = CreateUUId();

				service.$( "getRendererForField" ).$args( objectName=objectName, propertyName=propertyname ).$results( renderer );
				mockContentRenderer.$( "render" ).$args(
					  renderer = renderer
					, data     = value
					, context  = [ "adminview", "admin" ]
					, args     = { objectName=objectName, propertyName=propertyName, recordId=recordId }
				).$results( rendered );

				expect( service.renderField(
					  recordId     = recordId
					, objectName   = objectName
					, propertyName = propertyName
					, value        = value
				) ).toBe( rendered );
			} );
		} );

		describe( "getViewletForObjectRender()", function(){
			it( "should return specified 'adminViewRecordViewlet' attribute on the object when object defines it", function(){
				var service = _getService();
				var viewlet = "test.viewlet.#CreateUUId()#";

				mockPoService.$( "getObjectAttribute" ).$args( objectName="dummyobj", attributeName="adminViewRecordViewlet" ).$results( viewlet );

				expect( service.getViewletForObjectRender( "dummyobj" ) ).toBe( viewlet );
			} );

			it( "should return 'admin.dataHelpers.viewRecord' when no specific 'adminViewRecordViewlet' is defined on an object", function(){
				var service = _getService();

				mockPoService.$( "getObjectAttribute" ).$args( objectName="dummyobj", attributeName="adminViewRecordViewlet" ).$results( "" );

				expect( service.getViewletForObjectRender( "dummyobj" ) ).toBe( "admin.dataHelpers.viewRecord" );
			} );
		} );

		describe( "renderObjectRecord()", function(){
			it( "should use the configured viewlet for an object to render the view record view", function(){
				var service    = _getService();
				var rendered   = CreateUUid();
				var handler    = "";
				var args       = {
					  objectName = "test_object_" & CreateUUId()
					, recordId   = CreateUUId()
					, artbitrary = { test=true }
				};

				service.$( "getViewletForObjectRender" ).$args( objectName=args.objectName ).$results( handler );
				mockColdbox.$( "renderViewlet" ).$args(
					  event = handler
					, args  = args
				).$results( rendered );

				expect( service.renderObjectRecord( argumentCollection=args ) ).toBe( rendered );
			} );
		} );

		describe( "getBuildAdminLinkHandlerForObject()", function(){
			it( "should return the handler configured by the @adminBuildViewLinkHandler attribute on the object", function(){
				var service = _getService();
				var object  = "TestObject" & CreateUUId();
				var handler = "test." & CreateUUId();

				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = object
					, attributeName = "adminBuildViewLinkHandler"
				).$results( handler );

				expect( service.getBuildAdminLinkHandlerForObject( object ) ).toBe( handler );

			} );

			it( "should return a default admin handler for objects that do not define an @adminBuildViewLinkHandler attribute and that are managed by datamanager", function(){
				var service = _getService();
				var object  = "TestObject" & CreateUUId();
				var handler = "admin.dataHelpers.getViewRecordLink";

				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = object
					, attributeName = "adminBuildViewLinkHandler"
				).$results( "" );
				mockDataManagerService.$( "isObjectAvailableInDataManager" ).$args( objectName=object ).$results( true );

				expect( service.getBuildAdminLinkHandlerForObject( object ) ).toBe( handler );
			} );

			it( "should return an empty string (no handler) when object is not managed in datamanager and does not define the @adminBuildViewLinkHandler attribte", function(){
				var service = _getService();
				var object  = "TestObject" & CreateUUId();

				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = object
					, attributeName = "adminBuildViewLinkHandler"
				).$results( "" );
				mockDataManagerService.$( "isObjectAvailableInDataManager" ).$args( objectName=object ).$results( false );

				expect( service.getBuildAdminLinkHandlerForObject( object ) ).toBe( "" );
			} );
		} );

		describe( "doesObjectHaveBuildAdminLinkHandler()", function() {
			it( "should return true when getBuildAdminLinkHandlerForObject() returns non-empty", function(){
				var service    = _getService();
				var objectName = "my_object_#CreateUUId()#";

				service.$( "getBuildAdminLinkHandlerForObject" ).$args( objectName=objectName ).$results( "some.handler" );

				expect( service.doesObjectHaveBuildAdminLinkHandler( objectName ) ).toBe( true );
			} );

			it( "should return false when getBuildAdminLinkHandlerForObject() returns non-empty", function(){
				var service    = _getService();
				var objectName = "my_object_#CreateUUId()#";

				service.$( "getBuildAdminLinkHandlerForObject" ).$args( objectName=objectName ).$results( "" );

				expect( service.doesObjectHaveBuildAdminLinkHandler( objectName ) ).toBe( false );
			} );
		} );

		describe( "buildViewObjectRecordLink()", function(){
			it( "should return empty string when object does not have a build link handler", function(){
				var service    = _getService();
				var objectName = "test_object_" & CreateUUId();

				service.$( "doesObjectHaveBuildAdminLinkHandler" ).$args( objectName=objectName ).$results( false );

				expect( service.buildViewObjectRecordLink( objectName=objectName, recordId=CreateUUId() ) ).toBe( "" );
			} );

			it( "should return the result of calling the object's build admin link handler, passing through the supplied arguments", function(){
				var service    = _getService();
				var objectName = "test_object_" & CreateUUId();
				var builtLink  = CreateUUid();
				var handler    = "";
				var args       = {
					  objectName = "some_object_" & CreateUUId()
					, recordId   = CreateUUId()
					, artbitrary = { test=true }
				};

				service.$( "doesObjectHaveBuildAdminLinkHandler" ).$args( objectName=args.objectName ).$results( true );
				service.$( "getBuildAdminLinkHandlerForObject" ).$args( objectName=args.objectName ).$results( handler );
				mockColdbox.$( "runEvent" ).$args(
					  event          = handler
					, eventArguments = args
					, private        = true
					, prePostExempt  = true
				).$results( builtLink );

				expect( service.buildViewObjectRecordLink( argumentCollection=args ) ).toBe( builtLink );
			} );
		} );

		describe( "listRenderableObjectProperties()", function(){
			it( "should return an array of property names for an object sorted by sort order and excluding those whose admin renderer is 'none'", function(){
				var service    = _getService();
				var objectName = "someObject" & CreateUUId();
				var props      = StructNew( "linked" );

				props[ "propx"   ] = { sortorder=10  };
				props[ "propy"   ] = { sortorder=5   };
				props[ "propz"   ] = { sortorder=100 };
				props[ "test"    ] = {};
				props[ "testify" ] = { sortorder=39  };

				mockPoService.$( "getObjectProperties" ).$args( objectName=objectName ).$results( props );
				service.$( "getRendererForField" ).$args( objectName=objectName, propertyName="propx" ).$results( "none" );
				service.$( "getRendererForField", "testRenderer" );

				expect( service.listRenderableObjectProperties( objectName ) ).toBe( [
					  "propy"
					, "testify"
					, "propz"
					, "test"
				] );
			} );
		} );

		describe( "getDefaultViewGroupForProperty()", function(){
			it( "should return 'system' for system properties (datecreated, etc.)", function(){
				var service    = _getService();
				var objectName = "testObject" & CreateUUId();

				mockPoService.$( "getIdField"           ).$args( objectName ).$results( "__id"           );
				mockPoService.$( "getDateCreatedField"  ).$args( objectName ).$results( "__datecreated"  );
				mockPoService.$( "getDateModifiedField" ).$args( objectName ).$results( "__datemodified" );

				expect( service.getDefaultViewGroupForProperty( objectName, "__id"           ) ).toBe( "system" );
				expect( service.getDefaultViewGroupForProperty( objectName, "__datecreated"  ) ).toBe( "system" );
				expect( service.getDefaultViewGroupForProperty( objectName, "__datemodified" ) ).toBe( "system" );
			} );

			it( "should return empty string if property is a many-to-many or one-to-many field", function(){
				var service    = _getService();
				var objectName = "testObject" & CreateUUId();
				var m2mField   = "m2m"        & CreateUUId();
				var one2mField = "one2m"      & CreateUUId();

				mockPoService.$( "getIdField"           ).$args( objectName ).$results( "id"           );
				mockPoService.$( "getDateCreatedField"  ).$args( objectName ).$results( "datecreated"  );
				mockPoService.$( "getDateModifiedField" ).$args( objectName ).$results( "datemodified" );

				mockPoService.$( "getObjectPropertyAttribute" ).$args(
					  objectName    = objectName
					, propertyName  = m2mField
					, attributeName = "relationship"
				).$results( "many-to-many" );
				mockPoService.$( "getObjectPropertyAttribute" ).$args(
					  objectName    = objectName
					, propertyName  = one2mField
					, attributeName = "relationship"
				).$results( "one-to-many" );

				expect( service.getDefaultViewGroupForProperty( objectName, m2mField   ) ).toBe( "" );
				expect( service.getDefaultViewGroupForProperty( objectName, one2mField ) ).toBe( "" );
			} );

			it( "should return 'default' for all other fields", function(){
				var service    = _getService();
				var objectName = "testObject" & CreateUUId();

				mockPoService.$( "getIdField"           ).$args( objectName ).$results( "id"           );
				mockPoService.$( "getDateCreatedField"  ).$args( objectName ).$results( "datecreated"  );
				mockPoService.$( "getDateModifiedField" ).$args( objectName ).$results( "datemodified" );
				mockPoService.$( "getObjectPropertyAttribute", "" );

				expect( service.getDefaultViewGroupForProperty( objectName, "somefield" ) ).toBe( "default" );
			} );
		} );

		describe( "getViewGroupForProperty()", function(){
			it( "should return the group defined on the property using the 'adminViewGroup' attribute", function(){
				var service      = _getService();
				var objectName   = "testobjectName"   & CreateUUId();
				var propertyName = "testpropertyName" & CreateUUId();
				var groupName    = "testdefaultGroup" & CreateUUId();

				mockPoService.$( "getObjectPropertyAttribute" ).$args(
					  objectName   = objectName
					, propertyName = propertyName
					, attributeName = "adminViewGroup"
				).$results( groupName );

				expect( service.getViewGroupForProperty( objectName, propertyName ) ).toBe( groupName );
			} );

			it( "should return default group if property does not define its own", function(){
				var service      = _getService();
				var objectName   = "testobjectName"   & CreateUUId();
				var propertyName = "testpropertyName" & CreateUUId();
				var defaultGroup = "testdefaultGroup" & CreateUUId();

				mockPoService.$( "getObjectPropertyAttribute", "" );
				service.$( "getDefaultViewGroupForProperty" ).$args(
					  objectName   = objectName
					, propertyName = propertyName
				).$results( defaultGroup );

				expect( service.getViewGroupForProperty( objectName, propertyName ) ).toBe( defaultGroup );
			} );
		} );
	}

// HELPERS
	private any function _getService() {
		mockContentRenderer      = CreateEmptyMock( "preside.system.services.rendering.ContentRendererService" );
		mockPoService            = CreateEmptyMock( "preside.system.services.presideObjects.PresideObjectService" );
		mockDataManagerService   = CreateEmptyMock( "preside.system.services.admin.DataManagerService" );
		mockColdbox              = CreateStub();

		var service = CreateMock( object=new preside.system.services.admin.AdminDataViewsService(
			  contentRendererService = mockContentRenderer
			, dataManagerService     = mockDataManagerService
		) );

		service.$( "$getPresideObjectService", mockPoService );
		service.$( "$getColdbox", mockColdbox );

		return service;
	}

}