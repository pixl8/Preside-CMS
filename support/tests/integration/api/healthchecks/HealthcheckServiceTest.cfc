component extends="testbox.system.BaseSpec" {


	function run(){
		describe( "listRegisteredServices()", function(){
			it( "should return an array of service IDs by reading from system handlers in the 'healthcheck' folder", function(){
				var service = _getService( mockServices=[] );
				var handlers = [ "healthcheck.elasticsearch", "healthcheck.postcodelookup", "healthcheck.googlemaps" ];

				mockColdbox.$( "listHandlers" ).$args( thatStartWith="healthcheck." ).$results( handlers );

				expect( service.listRegisteredServices() ).toBe( [ "elasticsearch", "postcodelookup", "googlemaps" ] );
			} );

			it( "should only ever read from system handlers once, results should be cached after that", function(){
				var service = _getService( mockServices=[] );
				var handlers = [ "healthcheck.elasticsearch", "healthcheck.postcodelookup", "healthcheck.googlemaps" ];

				mockColdbox.$( "listHandlers" ).$args( thatStartWith="healthcheck." ).$results( handlers );

				expect( service.listRegisteredServices() ).toBe( [ "elasticsearch", "postcodelookup", "googlemaps" ] );
				expect( service.listRegisteredServices() ).toBe( [ "elasticsearch", "postcodelookup", "googlemaps" ] );
				expect( service.listRegisteredServices() ).toBe( [ "elasticsearch", "postcodelookup", "googlemaps" ] );

				expect( mockColdbox.$callLog().listHandlers.len() ).toBe( 1 );

			} );
		} );

		describe( "checkService()", function(){
			it( "should run the healthcheck for the given service and set the boolean result, retrievable with isUp() function", function(){
				var service   = _getService();

				mockColdbox.$( "runEvent" ).$args(
					  event = "healthcheck.elasticsearch.check"
					, private = true
					, prepostexempt = true
				).$results( true );

				expect( service.checkService( "elasticsearch" ) ).toBe( true );
				expect( service.isUp( "elasticsearch" ) ).toBe( true );

				mockColdbox.$( "runEvent" ).$args(
					  event = "healthcheck.elasticsearch.check"
					, private = true
					, prepostexempt = true
				).$results( false );

				expect( service.checkService( "elasticsearch" ) ).toBe( false );
				expect( service.isUp( "elasticsearch" ) ).toBe( false );
			} );

			it( "should return false when healthcheck returns a non boolean result", function(){
				var service   = _getService();

				mockColdbox.$( "runEvent" ).$args(
					  event = "healthcheck.elasticsearch.check"
					, private = true
					, prepostexempt = true
				).$results( {} );

				expect( service.checkService( "elasticsearch" ) ).toBe( false );
				expect( service.isUp( "elasticsearch" ) ).toBe( false );
			} );

			it( "should log error and return false when healthcheck throws an error", function(){
				var service = _getService();

				service.$( "$raiseerror" );
				mockColdbox.$( "runEvent" ).$args(
					  event = "healthcheck.elasticsearch.check"
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
		var service = createMock( object=new preside.system.services.healthchecks.HealthcheckService() );

		mockColdbox = createStub();
		service.$( "$getColdbox", mockColdbox );

		if ( arguments.mockServices.len() ) {
			service.$( "listRegisteredServices", arguments.mockServices );
		}

		return service;

	}

	private array function _defaultMockServices() {
		return [ "elasticsearch", "test", "another" ];
	}

}