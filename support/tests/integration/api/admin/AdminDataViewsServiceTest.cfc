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
	}

// HELPERS
	private any function _getService() {
		mockContentRenderer    = CreateEmptyMock( "preside.system.services.rendering.ContentRendererService" );
		mockPoService          = CreateEmptyMock( "preside.system.services.presideObjects.PresideObjectService" );
		mockDataManagerService = CreateEmptyMock( "preside.system.services.admin.DataManagerService" );

		var service = CreateMock( object=new preside.system.services.admin.AdminDataViewsService(
			  contentRendererService = mockContentRenderer
			, dataManagerService     = mockDataManagerService
		) );

		service.$( "$getPresideObjectService", mockPoService );

		return service;
	}

}