component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	public void function run() {
		describe( "getChangedFields()", function(){
			it( "should ignore changes when source and target number fields are equal in value but different in format", function(){
				var service = _getService();
				var objectName = "test_object_" & CreateUUId();
				var recordId = CreateUUId();
				var newData = { some_prop="1.000", another_prop="0.00" };
				var oldData = { some_prop=1, another_prop=0 };
				var props = {
					  some_prop    = { name="some_prop"   , type="numeric", dbtype="int"   }
					, another_prop = { name="another_prop", type="numeric", dbtype="float" }
				};

				service.$( "_getIgnoredFieldsForVersioning", [] );
				mockPresideObjectService.$( "isOneToManyConfiguratorObject", false );
				mockPresideObjectService.$( "getObjectProperties" ).$args( objectName ).$results( props );

				var changedFields = service.getChangedFields(
					  objectName             = objectName
					, recordId               = recordId
					, newData                = newData
					, existingData           = oldData
					, existingManyToManyData = {}
				);

				expect( changedFields.len() ).toBe( 0 );
			} );

			it( "should detect changes when source and target number fields are different in value and different in format", function(){
				var service = _getService();
				var objectName = "test_object_" & CreateUUId();
				var recordId = CreateUUId();
				var newData = { some_prop="1.33" };
				var oldData = { some_prop=1.26   };
				var props = {
					some_prop = { name="some_prop", type="numeric", dbtype="int" }
				};

				service.$( "_getIgnoredFieldsForVersioning", [] );
				mockPresideObjectService.$( "isOneToManyConfiguratorObject", false );
				mockPresideObjectService.$( "getObjectProperties" ).$args( objectName ).$results( props );

				var changedFields = service.getChangedFields(
					  objectName             = objectName
					, recordId               = recordId
					, newData                = newData
					, existingData           = oldData
					, existingManyToManyData = {}
				);

				expect( changedFields ).toBe( [ "some_prop" ] );
			} );
		} );
	}

// helpers
	private any function _getService() {
		var service = createMock( object=new preside.system.services.presideObjects.VersioningService() );

		mockPresideObjectService = createStub();

		service.$( "$getPresideObjectService", mockPresideObjectService );

		return service;
	}

}