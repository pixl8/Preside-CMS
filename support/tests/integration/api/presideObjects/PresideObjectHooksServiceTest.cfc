component extends="testbox.system.BaseSpec"{

	function run(){
		describe( "getColdboxEventForHook()", function(){
			it( "should return a conventions based handler action (preside-object-hooks.{object-name}.{hook-name}) based on hook name and preside object name", function(){
				var service    = _getService();
				var hook       = "postUpdateData";
				var objectName = "my_object"

				expect( service.getColdboxEventForHook( objectName, hook ) ).toBe( "preside-object-hooks.my_object.postUpdateData" );
			} );
		} );

		describe( "hasHook()", function(){
			it( "should return false when the given hook (action name) is not present in convention based handler", function(){
				var service      = _getService();
				var hook         = "postUpdateData";
				var objectName   = "my_object"
				var coldboxEvent = "preside-object-hooks.whatever.works.#CreateUUId()#";

				service.$( "getColdboxEventForHook" ).$args( objectName, hook ).$results( coldboxEvent );
				mockColdbox.$( "handlerExists" ).$args( coldboxEvent ).$results( false );

				expect( service.hasHook( objectName, hook ) ).toBeFalse();
			} );

			it( "should return true when the given hook (action name) is present in convention based handler", function(){
				var service           = _getService();
				var hook              = "postUpdateData";
				var objectName        = "my_object"
				var coldboxEvent = "preside-object-hooks.whatever.works.#CreateUUId()#";

				service.$( "getColdboxEventForHook" ).$args( objectName, hook ).$results( coldboxEvent );

				mockColdbox.$( "handlerExists" ).$args( coldboxEvent ).$results( true );

				expect( service.hasHook( objectName, hook ) ).toBeTrue();
			} );
		} );

		describe( "callHook()", function(){
			it( "should call the convention-based handler action for the object, passing through any supplied arguments", function(){
				var service      = _getService();
				var hook         = "myTestHook";
				var objectName   = "some_object";
				var coldboxEvent = "preside-object-hooks.whatever.works.#CreateUUId()#";
				var args         = { test=CreateUUId(), key={ value="test" } };
				var someResult   = CreateUUId();

				service.$( "getColdboxEventForHook" ).$args( objectName, hook ).$results( coldboxEvent );
				mockColdbox.$( "runEvent" ).$args(
					  event          = coldboxEvent
					, private        = true
					, prePostExempt  = true
					, eventArguments = { args=args }
				).$results( someResult );

				expect( service.callHook( objectName, hook, args ) ).toBe( someResult );
			} );
		} );
	}

// private helpers
	private any function _getService() {
		var service = new preside.system.services.presideObjects.PresideObjectHooksService();

		service = createMock( object=service );

		mockColdbox = CreateStub();

		service.$( "$getColdbox", mockColdbox );

		return service;
	}
}