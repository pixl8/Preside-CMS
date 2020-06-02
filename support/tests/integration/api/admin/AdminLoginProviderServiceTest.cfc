component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "renderProviderLoginPrompt()", function(){
			it( "should call the login provider's handler by convention, returning the string result", function(){
				var service      = _getService();
				var provider     = "preside";
				var rendered     = CreateUUId();
				var postLoginUrl = "https://#CreateUUId()#/";
				var position     = 4;

				mockColdbox.$( "renderViewlet" ).$args(
					  event = "admin.loginProvider.#provider#.prompt"
					, args  = { position=position, postLoginUrl=postLoginUrl }
				).$results( rendered );
				mockColdbox.$( "viewletExists" ).$args( "admin.loginProvider.#provider#.prompt" ).$results( true );

				expect( service.renderProviderLoginPrompt(
					  provider     = provider
					, postLoginUrl = postLoginUrl
					, position     = position
				) ).toBe( rendered );
			} );

			it( "should throw an informative error when the login provider's handler does not exist", function(){
				var service      = _getService();
				var provider     = "google";
				var postLoginUrl = "https://#CreateUUId()#/";
				var position     = 1;

				mockColdbox.$( "viewletExists" ).$args( "admin.loginProvider.#provider#.prompt" ).$results( false );

				expect( function() {
					service.renderProviderLoginPrompt(
						  provider     = provider
						, postLoginUrl = postLoginUrl
						, position     = position
					);
				} ).toThrow( "preside.admin.login.provider.not.found" );
			} );
		});

		describe( "isProviderEnabled()", function(){
			it( "should return whether or not the provider is in list of configured providers", function(){
				var service = _getService();
				var providers = [ "test", "providers" ];

				mockColdbox.$( "getSetting" ).$args( "adminLoginProviders" ).$results( providers );

				expect( service.isProviderEnabled( "test" ) ).toBeTrue();
				expect( service.isProviderEnabled( "providers" ) ).toBeTrue();
				expect( service.isProviderEnabled( CreateUUId() ) ).toBeFalse();
			} );
		} );
	}

	private any function _getService() {
		var service = createMock( object=new preside.system.services.admin.AdminLoginProviderService() );

		mockColdbox = CreateStub();

		service.$( "$getColdbox", mockColdbox );
		service.$( "$raiseError" );

		return service;
	}

}