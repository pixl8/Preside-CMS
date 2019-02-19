component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {

		describe( "create()", function(){

			it( "should save the impersonation data to cache, returning the modified URL with impersonate query param", function(){
				var service         = _getService();
				var userId          = CreateUUId();
				var impersonationId = CreateUUId();
				var targetUrl       = "http://example.com/";
				var expectedUrl     = targetUrl & "?impersonate=#impersonationId#";

				service.$( "_addImpersonation", impersonationId );

				var impersonateUrl = service.create(
					  userId    = userId
					, targetUrl = targetUrl
				);

				expect( impersonateUrl ).toBe( expectedUrl );
			} );

			it( "should save the impersonation data to cache, returning the modified URL with additional impersonate query param", function(){
				var service         = _getService();
				var userId          = CreateUUId();
				var impersonationId = CreateUUId();
				var targetUrl       = "http://example.com/?key=value";
				var expectedUrl     = targetUrl & "&impersonate=#impersonationId#";

				service.$( "_addImpersonation", impersonationId );

				var impersonateUrl = service.create(
					  userId    = userId
					, targetUrl = targetUrl
				);

				expect( impersonateUrl ).toBe( expectedUrl );
			} );

		} );

		describe( "resolve()", function(){

			it( "should log user in and return target URL from cache if impersonation found in cache", function(){
				var service         = _getService();
				var userId          = CreateUUId();
				var impersonationId = CreateUUId();
				var targetUrl       = "http://example.com/";

				mockWebsiteLoginService.$( "impersonate", true );
				mockCacheProvider.$( "get", { userId=userId, targetUrl=targetUrl } );
				mockCacheProvider.$( "clear", true );

				var returnedUrl = service.resolve( impersonationId );

				expect( mockWebsiteLoginService.$once( "impersonate" ) ).toBeTrue();
				expect( mockCacheProvider.$once( "clear" ) ).toBeTrue();
				expect( returnedUrl ).toBe( targetUrl );
			} );

			it( "should return empty target URL if impersonation not found in cache", function(){
				var service         = _getService();
				var impersonationId = CreateUUId();

				mockCacheProvider.$( "get", nullValue() );

				var returnedUrl = service.resolve( impersonationId );

				expect( returnedUrl ).toBeEmpty();
			} );

		} );

	}


// PRIVATE HELPERS
	private any function _getService() {
		mockWebsiteLoginService = createEmptyMock( "preside.system.services.websiteUsers.websiteLoginService" );
		mockCacheProvider       = getMockbox().createStub();

		var service = createMock( object=new preside.system.services.websiteUsers.WebsiteUserImpersonationService(
			  websiteLoginService = mockWebsiteLoginService
			, cacheProvider       = mockCacheProvider
		) );

		return service;
	}
}