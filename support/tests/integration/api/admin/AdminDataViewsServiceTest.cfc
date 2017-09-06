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
	}

// HELPERS
	private any function _getService() {
		var service = CreateMock( object=new preside.system.services.admin.AdminDataViewsService() );

		mockPoService = CreateEmptyMock( "preside.system.services.presideObjects.PresideObjectService" );

		service.$( "$getPresideObjectService", mockPoService );

		return service;
	}

}