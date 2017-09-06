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
				var service = _getService();

				mockPoService.$( "getObjectProperty" ).$args( "testobject", "testprop" ).$results( { type="string", dbtype="varchar", relationship="none" } );
				expect( service.getRendererForField( "testobject", "testprop" ) ).toBe( "plaintext" );

				mockPoService.$( "getObjectProperty" ).$args( "testobject2", "testprop2" ).$results( { type="string", dbtype="text", relationship="none" } );
				expect( service.getRendererForField( "testobject2", "testprop2" ) ).toBe( "richeditor" );

				mockPoService.$( "getObjectProperty" ).$args( "testobject2", "testprop2" ).$results( { type="string", dbtype="longtext", relationship="none" } );
				expect( service.getRendererForField( "testobject2", "testprop2" ) ).toBe( "richeditor" );

				mockPoService.$( "getObjectProperty" ).$args( "testobject2", "testprop2" ).$results( { type="string", dbtype="mediumtext", relationship="none" } );
				expect( service.getRendererForField( "testobject2", "testprop2" ) ).toBe( "richeditor" );

				mockPoService.$( "getObjectProperty" ).$args( "testobject", "testprop" ).$results( { type="date", dbtype="datetime", relationship="none" } );
				expect( service.getRendererForField( "testobject", "testprop" ) ).toBe( "datetime" );

				mockPoService.$( "getObjectProperty" ).$args( "testobject", "testprop" ).$results( { type="date", dbtype="timestamp", relationship="none" } );
				expect( service.getRendererForField( "testobject", "testprop" ) ).toBe( "datetime" );

				mockPoService.$( "getObjectProperty" ).$args( "testobject", "testprop" ).$results( { type="date", dbtype="date", relationship="none" } );
				expect( service.getRendererForField( "testobject", "testprop" ) ).toBe( "date" );

				mockPoService.$( "getObjectProperty" ).$args( "testobject", "testprop" ).$results( { type="boolean", dbtype="boolean", relationship="none" } );
				expect( service.getRendererForField( "testobject", "testprop" ) ).toBe( "boolean" );

				mockPoService.$( "getObjectProperty" ).$args( "testobject", "testprop" ).$results( { type="boolean", dbtype="bit", relationship="none" } );
				expect( service.getRendererForField( "testobject", "testprop" ) ).toBe( "boolean" );

				mockPoService.$( "getObjectProperty" ).$args( "testobject", "testprop" ).$results( { relationship="many-to-one", relatedto="something" } );
				expect( service.getRendererForField( "testobject", "testprop" ) ).toBe( "manyToOne" );

				mockPoService.$( "getObjectProperty" ).$args( "testobject", "testprop" ).$results( { relationship="many-to-one", relatedto="asset" } );
				expect( service.getRendererForField( "testobject", "testprop" ) ).toBe( "asset" );

				mockPoService.$( "getObjectProperty" ).$args( "testobject", "testprop" ).$results( { relationship="many-to-one", relatedto="link" } );
				expect( service.getRendererForField( "testobject", "testprop" ) ).toBe( "link" );

				mockPoService.$( "getObjectProperty" ).$args( "testobject", "testprop" ).$results( { relationship="one-to-many", relatedto="blah" } );
				expect( service.getRendererForField( "testobject", "testprop" ) ).toBe( "objectRelatedRecords" );

				mockPoService.$( "getObjectProperty" ).$args( "testobject", "testprop" ).$results( { relationship="many-to-many", relatedto="blah" } );
				expect( service.getRendererForField( "testobject", "testprop" ) ).toBe( "objectRelatedRecords" );
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
	}

// HELPERS
	private any function _getService() {
		mockContentRenderer = CreateEmptyMock( "preside.system.services.rendering.ContentRendererService" );
		mockPoService       = CreateEmptyMock( "preside.system.services.presideObjects.PresideObjectService" );

		var service = CreateMock( object=new preside.system.services.admin.AdminDataViewsService(
			contentRendererService = mockContentRenderer
		) );

		service.$( "$getPresideObjectService", mockPoService );

		return service;
	}

}