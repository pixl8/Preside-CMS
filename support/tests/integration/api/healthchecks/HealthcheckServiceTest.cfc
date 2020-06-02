component extends="testbox.system.BaseSpec" {


	function run(){
		describe( "listRegisteredServices()", function(){
			it( "should return an array of service IDs from the configured services", function(){
				var service = _getService();
				var services = service.listRegisteredServices();

				services.sort( "textnocase" );

				expect( services ).toBe( [ "another", "elasticsearch", "test" ] );
			} );
		} );

		describe( "checkService()", function(){
			it( "should run the default healthcheck event for the given service and set the boolean result, retrievable with isUp() function", function(){
				var service   = _getService();

				mockColdbox.$( "runEvent" ).$args(
					  event = "healthcheck.another.check"
					, private = true
					, prepostexempt = true
				).$results( true );

				expect( service.checkService( "another" ) ).toBe( true );
				expect( service.isUp( "another" ) ).toBe( true );

				mockColdbox.$( "runEvent" ).$args(
					  event = "healthcheck.another.check"
					, private = true
					, prepostexempt = true
				).$results( false );

				expect( service.checkService( "another" ) ).toBe( false );
				expect( service.isUp( "another" ) ).toBe( false );
			} );

			it( "should run the configured healthcheck event for the given service and set the boolean result, retrievable with isUp() function", function(){
				var service   = _getService();

				mockColdbox.$( "runEvent" ).$args(
					  event = "test.handler.here"
					, private = true
					, prepostexempt = true
				).$results( true );

				expect( service.checkService( "elasticsearch" ) ).toBe( true );
				expect( service.isUp( "elasticsearch" ) ).toBe( true );

				mockColdbox.$( "runEvent" ).$args(
					  event = "test.handler.here"
					, private = true
					, prepostexempt = true
				).$results( false );

				expect( service.checkService( "elasticsearch" ) ).toBe( false );
				expect( service.isUp( "elasticsearch" ) ).toBe( false );
			} );

			it( "should return false when healthcheck returns a non boolean result", function(){
				var service   = _getService();

				mockColdbox.$( "runEvent" ).$args(
					  event = "test.handler.here"
					, private = true
					, prepostexempt = true
				).$results( {} );

				expect( service.checkService( "elasticsearch" ) ).toBe( false );
				expect( service.isUp( "elasticsearch" ) ).toBe( false );
			} );

			it( "should log error and return false when healthcheck throws an error", function(){
				var service = _getService();

				mockColdbox.$( "runEvent" ).$args(
					  event = "test.handler.here"
					, private = true
					, prepostexempt = true
				).$throws( "any.old.error" );

				expect( service.checkService( "elasticsearch" ) ).toBe( false );
				expect( service.$callLog().$raiseError.len() ).toBe( 1 );
				expect( service.isUp( "elasticsearch" ) ).toBe( false );
			} );

			it( "should return false when the service is not registered", function(){
				var service   = _getService();
				var serviceId = "blah" & CreateUUId();

				mockColdbox.$( "runEvent" ).$args(
					  event = "healthcheck.#serviceId#.check"
					, private = true
					, prepostexempt = true
				).$results( true );

				expect( service.checkService( serviceId ) ).toBe( false );
				expect( service.isUp( "elasticsearch" ) ).toBe( false );
			} );
		} );

		describe( "isUp()", function(){
			it( "should return false when the service does not exist", function(){
				var service = _getService();

				expect( service.isUp( "bah" & CreateUUId() ) ).toBe( false );
			} );

			it( "should return false when service has not yet been checked", function(){
				var service = _getService();

				expect( service.isUp( "elasticsearch" ) ).toBe( false );
			} );

			it( "should return the last set status", function(){
				var service = _getService();

				service.setIsUp( "elasticsearch", true )
				expect( service.isUp( "elasticsearch" ) ).toBe( true );
				service.setIsUp( "elasticsearch", false )
				expect( service.isUp( "elasticsearch" ) ).toBe( false );
			} );
		} );

	}

	private any function _getService( mockServices=_defaultMockServices() ) {
		var service = createMock( object=new preside.system.services.healthchecks.HealthcheckService(
			  configuredServices = arguments.mockServices
		) );

		mockColdbox = createStub();
		service.$( "$getColdbox", mockColdbox );
		service.$( "$raiseerror" );

		return service;
	}

	private struct function _defaultMockServices() {
		return {
			  elasticsearch = { interval=CreateTimeSpan( 0, 0, 1, 0 ), handler="test.handler.here" }
			, test          = {}
			, another       = {}
		};
	}

}