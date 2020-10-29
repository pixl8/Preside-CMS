component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "getGlobalCustomizationHandler()", function(){
			it( "should return a conventions based handler path", function(){
				var service    = _getService();

				expect( service.getGlobalCustomizationHandler() ).toBe( "admin.datamanager.GlobalCustomizations" );
			} );
		} );

		describe( "getGlobalCustomizationEvent()", function(){
			it( "should append customization action to customization handler", function(){
				var service       = _getService();
				var customization = "buildCrumbtrail";
				var handler       = "some.handler";
				var event         = "some.handler.buildCrumbtrail";

				service.$( "getGlobalCustomizationHandler", handler );
				mockColdbox.$( "handlerExists" ).$args( event ).$results( true );

				expect( service.getGlobalCustomizationEvent( customization ) ).toBe( event );
			} );

			it( "should return empty string when handler action does not exist", function(){
				var service       = _getService();
				var customization = "buildCrumbtrail";
				var handler       = "some.handler";
				var event         = "some.handler.buildCrumbtrail";

				service.$( "getGlobalCustomizationHandler", handler );
				mockColdbox.$( "handlerExists" ).$args( event ).$results( false );

				expect( service.getGlobalCustomizationEvent( customization ) ).toBe( "" );
			} );
		} );

		describe( "getCustomizationHandlerForObject()", function(){
			it( "should return a conventions based handler path when object does not specify its own", function(){
				var service    = _getService();
				var objectName = "some_object";

				mockPresideObjectService.$( "getObjectAttribute" ).$args( objectName, "datamanagerHandler" ).$results( "" );

				expect( service.getCustomizationHandlerForObject( objectName ) ).toBe( "admin.datamanager.some_object" );
			} );

			it( "should return the value of @datamanagerHandler if set on the object", function(){
				var service    = _getService();
				var objectName = "some_object";
				var handler    = "blah.test";

				mockPresideObjectService.$( "getObjectAttribute" ).$args( objectName, "datamanagerHandler" ).$results( handler );

				expect( service.getCustomizationHandlerForObject( objectName ) ).toBe( handler );
			} );
		} );

		describe( "getCustomizationEventForObject()", function(){
			it( "should append customization action to customization handler for the object", function(){
				var service       = _getService();
				var objectName    = "my_object";
				var customization = "buildCrumbtrail";
				var handler       = "some.handler";
				var event         = "some.handler.buildCrumbtrail";

				service.$( "getCustomizationHandlerForObject" ).$args( objectName ).$results( handler );
				mockColdbox.$( "handlerExists" ).$args( event ).$results( true );

				expect( service.getCustomizationEventForObject( objectName, customization ) ).toBe( event );
			} );

			it( "should return the global customization if no customization exists for the object", function(){
				var service       = _getService();
				var objectName    = "my_object";
				var customization = "buildCrumbtrail";
				var objectHandler = "some.handler";
				var objectEvent   = "some.handler.buildCrumbtrail";
				var globalEvent   = "some.altogether.different.handler.buildCrumbtrail";

				service.$( "getCustomizationHandlerForObject" ).$args( objectName ).$results( objecthandler );
				service.$( "getGlobalCustomizationEvent" ).$args( customization ).$results( globalEvent );
				mockColdbox.$( "handlerExists" ).$args( objectEvent ).$results( false );

				expect( service.getCustomizationEventForObject( objectName, customization ) ).toBe( globalEvent );
			} );
		} );

		describe( "objectHasCustomization()", function(){
			it( "should return true when coldbox handler exists", function(){
				var service       = _getService();
				var objectName    = "my_object";
				var customization = "buildCrumbtrail";
				var event         = "some.handler.buildCrumbtrail";

				service.$( "getCustomizationEventForObject" ).$args( objectName, customization ).$results( event );

				expect( service.objectHasCustomization( objectName, customization ) ).toBe( true );
			} );

			it( "should return false when coldbox handler does not exist", function(){
				var service       = _getService();
				var objectName    = "my_object";
				var customization = "buildCrumbtrail";
				var event         = "";

				service.$( "getCustomizationEventForObject" ).$args( objectName, customization ).$results( event );

				expect( service.objectHasCustomization( objectName, customization ) ).toBe( false );
			} );
		} );

		describe( "runCustomization()", function(){
			it( "should run the coldbox action for the given customization for the object, passing through any given args", function(){
				var service       = _getService();
				var objectName    = "my_object";
				var customization = "buildCrumbtrail";
				var event         = "some.handler.buildCrumbtrail";
				var result        = CreateUUId();
				var args          = { test=CreateUUId(), blah={ test=CreateUUId(), blah="not recursive" } };

				service.$( "getCustomizationEventForObject" ).$args( objectName, customization ).$results( event );
				mockColdbox.$( "runEvent" ).$args(
					  event         = event
					, private       = true
					, prepostExempt = true
					, eventArguments = { args=args }
				).$results( result );

				expect( service.runCustomization( objectName, customization, args ) ).toBe( result );
			} );

			it( "should run the passed 'defaultHandler' if the object does not have the given customization", function(){
				var service       = _getService();
				var objectName    = "my_object";
				var customization = "buildCrumbtrail";
				var event         = "";
				var result        = CreateUUId();
				var args          = { test=CreateUUId(), blah={ test=CreateUUId(), blah="not recursive" } };
				var defaultHandler = "another.handler.yikes";

				service.$( "getCustomizationEventForObject" ).$args( objectName, customization ).$results( event );
				mockColdbox.$( "runEvent" ).$args(
					  event         = defaultHandler
					, private       = true
					, prepostExempt = true
					, eventArguments = { args=args }
				).$results( result );

				expect( service.runCustomization( objectName=objectName, action=customization, args=args, defaultHandler=defaultHandler ) ).toBe( result );
			} );

			it( "should do nothing when object does not have customization and no default handler passed", function(){
				var service       = _getService();
				var objectName    = "my_object";
				var customization = "buildCrumbtrail";
				var event         = "";
				var result        = CreateUUId();
				var args          = { test=CreateUUId(), blah={ test=CreateUUId(), blah="not recursive" } };
				var defaultHandler = "";

				service.$( "getCustomizationEventForObject" ).$args( objectName, customization ).$results( event );
				mockColdbox.$( "runEvent" ).$args(
					  event         = defaultHandler
					, private       = true
					, prepostExempt = true
					, eventArguments = { args=args }
				).$results( result );

				expect( service.runCustomization( objectName=objectName, action=customization, args=args, defaultHandler=defaultHandler ) ).toBeNull();
				expect( mockColdbox.$callLog().runEvent.len() ).toBe( 0 );
			} );
		} );
	}

// private helpers
	private any function _getService() {
		var service = createMock( object=new preside.system.services.admin.DataManagerCustomizationService() );

		mockPresideObjectService = CreateStub();
		mockColdbox              = CreateStub();

		service.$( "$getPresideObjectService", mockPresideObjectService );
		service.$( "$getColdbox", mockColdbox );

		return service;
	}
}