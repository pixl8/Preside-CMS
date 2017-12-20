component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "buildLink", function(){
			it( "should call customization action based on operation name", function(){
				var service        = _getService();
				var objectName     = "some_obejct";
				var link           = "test" & CreateUUId();
				var recordId       = CreateUUId();
				var operation      = "someoperation";
				var additionalArgs = { test="tis" }

				mockCustomizationService.$( "runCustomization" ).$args(
					  objectName     = objectName
					, action         = "build#operation#Link"
					, args           = { objectName=objectName, recordId=recordId, test="tis" }
					, defaultHandler = "admin.objectLinks.build#operation#Link"
				).$results( link );

				expect( service.buildlink( objectName=objectName, operation=operation, recordId=recordId, args=additionalArgs ) ).toBe( link );
			} );

			it( "should return an empty string when action returns null (i.e. no matching link builder found)", function(){
				var service    = _getService();
				var objectName = "some_obejct";
				var recordId   = CreateUUId();
				var operation  = "someoperation";

				mockCustomizationService.$( "runCustomization" ).$args(
					  objectName     = objectName
					, action         = "build#operation#Link"
					, args           = { objectName=objectName, recordId=recordId }
					, defaultHandler = "admin.objectLinks.build#operation#Link"
				).$results( NullValue() );

				expect( service.buildlink( objectName=objectName, operation=operation, recordId=recordId ) ).toBe( "" );
			} );

			it( "should return empty string when result is not a string", function(){
				var service    = _getService();
				var objectName = "some_obejct";
				var recordId   = CreateUUId();
				var operation  = "someoperation";

				mockCustomizationService.$( "runCustomization" ).$args(
					  objectName     = objectName
					, action         = "build#operation#Link"
					, args           = { objectName=objectName, recordId=recordId }
					, defaultHandler = "admin.objectLinks.build#operation#Link"
				).$results( { test=true } );

				expect( service.buildlink( objectName=objectName, operation=operation, recordId=recordId ) ).toBe( "" );
			} );
		} );
	}

// HELPERS
	private any function _getService() {
		mockCustomizationService = CreateEmptyMock( "preside.system.services.admin.DataManagerCustomizationService" );

		var service = CreateMock( object=new preside.system.services.admin.AdminObjectLinkBuilderService(
			  customizationService = mockCustomizationService
		) );

		return service;
	}

}