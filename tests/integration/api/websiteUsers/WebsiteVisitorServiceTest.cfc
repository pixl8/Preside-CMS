component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "getVisitorId()", function(){
			it( "should return value stored in visitor cookie, if exists", function(){
				var service   = _getService();
				var visitorId = CreateUUId();

				mockCookieService.$( "getVar" ).$args( name="vid", default="" ).$results( visitorId );

				expect( service.getVisitorId() ).toBe( visitorId );
			} );

			it( "should return the result of creating a new visitor, when no cookie value is stored", function(){
				var service   = _getService();
				var visitorId = CreateUUId();

				mockCookieService.$( "getVar" ).$args( "vid" ).$results( "" );
				service.$( "createVisitor", visitorId );

				expect( service.getVisitorId() ).toBe( visitorId );
			} );
		} );

		describe( "createVisitor", function(){
			it( "should do nothing when sessions are disabled for the request (i.e. stateless requests)", function(){
				var service = _getService();

				service.$( "_sessionsAreEnabled", false );
				expect( service.createVisitor() ).toBe( "" );
			} );

			it( "should set visitor cookie and return its value", function(){
				var service          = _getService();
				var visitorId        = service.createVisitor();
				var setCookieCallLog = mockCookieService.$callLog().setVar;

				expect( setCookieCallLog.len() ).toBe( 1 );
				expect( setCookieCallLog[1] ).toBe( {
					  name    = "vid"
					, value   = visitorId
					, expires = "never"
				} );
			} );
		} );
	}

// PRIVATE HELPERS
	private any function _getService() {
		mockCookieService = CreateEmptyMock( "preside.system.services.cfmlscopes.CookieService" );

		var service = createMock( object=new preside.system.services.websiteUsers.WebsiteVisitorService(
			cookieService = mockCookieService
		) );

		service.$( "_sessionsAreEnabled", true );
		service.$( "$getPresideSetting" ).$args( "tracking", "vid_cookie_expiry" ).$results( "" );
		mockCookieService.$( "setVar" );

		return service;
	}
}