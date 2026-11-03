component extends="testbox.system.BaseSpec" {

	function run() {
		describe( "_blockDirectEventDispatch()", function() {
			it( "should remove the configured event parameter when direct event dispatch is disabled", function() {
				var requestCollection = { event="admin.login.login" };
				var service           = _getRoutingService( false );
				var event             = _getRequestContext( requestCollection );

				service._blockDirectEventDispatch( event );

				expect( StructKeyExists( requestCollection, "event" ) ).toBeFalse();
			} );

			it( "should preserve the configured event parameter when direct event dispatch is enabled", function() {
				var requestCollection = { event="admin.login.login" };
				var service           = _getRoutingService( true );
				var event             = _getRequestContext( requestCollection );

				service._blockDirectEventDispatch( event );

				expect( requestCollection.event ).toBe( "admin.login.login" );
			} );
		} );
	}

	private any function _getRoutingService( required boolean allowDirectEventDispatch ) {
		var featureService = getMockBox().createEmptyMock( "preside.system.services.features.FeatureService" );
		var service        = prepareMock( new preside.system.coldboxModifications.services.RoutingService() );

		featureService.$( "isFeatureEnabled", arguments.allowDirectEventDispatch );
		service.$property( propertyName="featureService", mock=featureService );
		service.$property( propertyName="eventName", mock="event" );
		makePublic( service, "_blockDirectEventDispatch" );

		return service;
	}

	private any function _getRequestContext( required struct requestCollection ) {
		var event = getMockBox().createStub();

		event.$( "getCollection", arguments.requestCollection );

		return event;
	}
}
