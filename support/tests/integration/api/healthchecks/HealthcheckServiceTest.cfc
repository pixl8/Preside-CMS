component extends="testbox.system.BaseSpec" {


	function run(){
		describe( "readServicesFromHandlers()", function(){
			it( "should return an array of services and their configuration by reading from system handlers named 'healthcheck'", function(){
				var service = _getService();
				var handlers = [ "healthcheck.elasticsearch", "healthcheck.postcodelookup", "healthcheck.googlemaps" ];

				mockColdbox.$( "listHandlers" ).$args( thatStartWith="healthcheck." ).$results( handlers );

				expect( service.readServicesFromHandlers() ).toBe( [ "elasticsearch", "postcodelookup", "googlemaps" ] );
			} );
		} );

	}

	private any function _getService( mockServices=_defaultMockServices() ) {
		var service = createMock( object=new preside.system.services.healthchecks.HealthcheckService() );

		mockColdbox = createStub();
		service.$( "$getColdbox", mockColdbox );

		return service;

	}

	private array function _defaultMockServices() {
		return [];
	}

}