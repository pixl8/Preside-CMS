component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "buildLink()", function(){
			it( "should call admin.objectLinks handler action based on operation name", function(){
				var service        = _getService();
				var objectName     = "some_obejct";
				var link           = "test" & CreateUUId();
				var recordId       = CreateUUId();
				var operation      = "someoperation";
				var additionalArgs = { test="tis" }

				mockColdbox.$( "runEvent" ).$args(
					  event = "admin.objectLinks.build#operation#Link"
					, private = true
					, prePostExempt = true
					, eventArguments = { args={ objectName=objectName, recordId=recordId, test="tis" } }
				).$results( link );

				expect( service.buildlink( objectName=objectName, operation=operation, recordId=recordId, args=additionalArgs ) ).toBe( link );
			} );

			it( "should call customization handler action based on operation name when customization exists", function(){
				var service        = _getService();
				var objectName     = "some_obejct";
				var link           = "test" & CreateUUId();
				var recordId       = CreateUUId();
				var operation      = "someoperation";
				var additionalArgs = { test="tis" }

				mockCustomizationService.$( "objectHasCustomization" ).$args( objectName, "build#operation#Link" ).$results( true );
				mockCustomizationService.$( "runCustomization" ).$args(
					  objectName     = objectName
					, action         = "build#operation#Link"
					, args           = { objectName=objectName, recordId=recordId, test="tis" }
				).$results( link );

				expect( service.buildlink( objectName=objectName, operation=operation, recordId=recordId, args=additionalArgs ) ).toBe( link );
			} );

			it( "should return an empty string when action returns null (i.e. no matching link builder found)", function(){
				var service    = _getService();
				var objectName = "some_obejct";
				var recordId   = CreateUUId();
				var operation  = "someoperation";

				mockCustomizationService.$( "objectHasCustomization" ).$args( objectName, "build#operation#Link" ).$results( true );
				mockCustomizationService.$( "runCustomization" ).$args(
					  objectName     = objectName
					, action         = "build#operation#Link"
					, args           = { objectName=objectName, recordId=recordId }
				).$results( NullValue() );

				expect( service.buildlink( objectName=objectName, operation=operation, recordId=recordId ) ).toBe( "" );
			} );

			it( "should return empty string when result is not a string", function(){
				var service    = _getService();
				var objectName = "some_obejct";
				var recordId   = CreateUUId();
				var operation  = "someoperation";

				mockCustomizationService.$( "objectHasCustomization" ).$args( objectName, "build#operation#Link" ).$results( true );
				mockCustomizationService.$( "runCustomization" ).$args(
					  objectName     = objectName
					, action         = "build#operation#Link"
					, args           = { objectName=objectName, recordId=recordId }
				).$results( { test=true } );

				expect( service.buildlink( objectName=objectName, operation=operation, recordId=recordId ) ).toBe( "" );
			} );

			it( "should use default operation of 'listing' when no operation or recordId is passed", function(){
				var service    = _getService();
				var objectName = "some_obejct";
				var result     = CreateUUId();

				mockCustomizationService.$( "objectHasCustomization" ).$args( objectName, "buildListingLink" ).$results( true );
				mockCustomizationService.$( "runCustomization" ).$args(
					  objectName     = objectName
					, action         = "buildListingLink"
					, args           = { objectName=objectName }
				).$results( result );

				expect( service.buildlink( objectName=objectName ) ).toBe( result );
			} );

			it( "should get object default record action when no operation passed but record ID passed", function(){
				var service          = _getService();
				var objectName       = "some_obejct";
				var recordId         = CreateUUId();
				var result           = CreateUUId();
				var defaultOperation = "blah" & CreateUUId();

				mockCustomizationService.$( "objectHasCustomization" ).$args( objectName, "build#defaultOperation#Link" ).$results( true );
				mockCustomizationService.$( "runCustomization" ).$args(
					  objectName     = objectName
					, action         = "build#defaultOperation#Link"
					, args           = { objectName=objectName, recordId=recordId }
				).$results( result );
				service.$( "getDefaultRecordOperation" ).$args( objectName ).$results( defaultOperation );

				expect( service.buildlink(
					  objectName = objectName
					, recordId   = recordId
				) ).toBe( result );
			} );

			it( "should return an empty string when no custom builder is defined and the object is not manageable in the data manager", function(){
				var service          = _getService();
				var objectName       = "some_obejct";
				var recordId         = CreateUUId();
				var defaultOperation = "whatever";

				service.$( "getDefaultRecordOperation" ).$args( objectName ).$results( defaultOperation );
				mockCustomizationService.$( "objectHasCustomization" ).$args( objectName, "build#defaultOperation#Link" ).$results( false );
				mockDataManagerService.$( "isObjectAvailableInDataManager" ).$args( objectName ).$results( false );

				expect( service.buildlink(
					  objectName = objectName
					, recordId   = recordId
				) ).toBe( "" );
			} );

			it( "should build link for 'page' object when object is a page type", function(){
				var service          = _getService();
				var objectName       = "some_obejct";
				var recordId         = CreateUUId();
				var defaultOperation = "whatever";
				var result           = CreateUUId();

				mockPresideObjectService.$( "isPageType" ).$args( objectName ).$results( true );
				service.$( "getDefaultRecordOperation" ).$args( "page" ).$results( defaultOperation );
				mockCustomizationService.$( "objectHasCustomization" ).$args( "page", "build#defaultOperation#Link" ).$results( true );
				mockCustomizationService.$( "runCustomization" ).$args(
					  objectName     = "page"
					, action         = "build#defaultOperation#Link"
					, args           = { objectName="page", recordId=recordId }
				).$results( result );

				expect( service.buildlink(
					  objectName = objectName
					, recordId   = recordId
				) ).toBe( result );
			} );
		} );

		describe( "getDefaultRecordOperation()", function(){
			it( "should return datamanagerDefaultRecordOperation attribute when set on the object", function(){
				var service    = _getService();
				var objectName = "test_object";
				var operation  = "foodlibar" & CreateUUId();

				mockPresideObjectService.$( "getObjectAttribute" ).$args(
					  objectName    = objectName
					, attributeName = "datamanagerDefaultRecordOperation"
				).$results( operation );

				expect( service.getDefaultRecordOperation( objectName ) ).toBe( operation );
			} );

			it( "should return viewRecord when 'read' operation is allowed", function(){
				var service    = _getService();
				var objectName = "test_object";

				mockPresideObjectService.$( "getObjectAttribute" ).$args(
					  objectName    = objectName
					, attributeName = "datamanagerDefaultRecordOperation"
				).$results( "" );

				mockDataManagerService.$( "isOperationAllowed" ).$args(
					  objectName = objectName
					, operation  = "read"
				).$results( true );

				expect( service.getDefaultRecordOperation( objectName ) ).toBe( "viewRecord" );
			} );

			it( "should return editRecord when 'read' operation is not allowed and edit _is_ allowed", function(){
				var service    = _getService();
				var objectName = "test_object";

				mockPresideObjectService.$( "getObjectAttribute" ).$args(
					  objectName    = objectName
					, attributeName = "datamanagerDefaultRecordOperation"
				).$results( "" );

				mockDataManagerService.$( "isOperationAllowed" ).$args(
					  objectName = objectName
					, operation  = "read"
				).$results( false );

				mockDataManagerService.$( "isOperationAllowed" ).$args(
					  objectName = objectName
					, operation  = "edit"
				).$results( true );

				expect( service.getDefaultRecordOperation( objectName ) ).toBe( "editRecord" );
			} );

			it( "should return listing when 'read' and 'edit' operations are not allowed", function(){
				var service    = _getService();
				var objectName = "test_object";

				mockPresideObjectService.$( "getObjectAttribute" ).$args(
					  objectName    = objectName
					, attributeName = "datamanagerDefaultRecordOperation"
				).$results( "" );

				mockDataManagerService.$( "isOperationAllowed" ).$args(
					  objectName = objectName
					, operation  = "read"
				).$results( false );

				mockDataManagerService.$( "isOperationAllowed" ).$args(
					  objectName = objectName
					, operation  = "edit"
				).$results( false );

				expect( service.getDefaultRecordOperation( objectName ) ).toBe( "listing" );
			} );
		} );
	}

// HELPERS
	private any function _getService() {
		mockCustomizationService = CreateEmptyMock( "preside.system.services.admin.DataManagerCustomizationService" );
		mockDataManagerService   = CreateEmptyMock( "preside.system.services.admin.DataManagerService" );
		mockPresideObjectService = CreateEmptyMock( "preside.system.services.presideObjects.PresideObjectService" );
		mockColdbox              = CreateStub();

		var service = CreateMock( object=new preside.system.services.admin.AdminObjectLinkBuilderService(
			  customizationService = mockCustomizationService
			, dataManagerService   = mockDataManagerService
		) );

		service.$( "$getPresideObjectService", mockPresideObjectService );
		service.$( "$getColdbox", mockColdbox );

		mockCustomizationService.$( "objectHasCustomization", false );
		mockDataManagerService.$( "isObjectAvailableInDataManager", true );
		mockColdbox.$( "runEvent", CreateUUId() );
		mockPresideObjectService.$( "isPageType", false );

		return service;
	}

}