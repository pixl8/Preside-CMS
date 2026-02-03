component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// SETUP, etc
	function setup() {
		variables.tokenExpiryInSeconds = 5;
		variables.sessionStorage       = new tests.resources.HelperObjects.TestSessionStorage();
	}

// TESTS
	function test01_generateToken_shouldReturnARandomlyGeneratedToken(){
		super.assert( Len( _getSvc().generateToken() ) );
	}

	function test02_validateToken_shouldReturnFalse_whenNoCallToGenerateATokenHasBeenMade(){
		super.assertFalse( _getSvc().validateToken( CreateUUId() ) );
	}

	function test03_validateToken_shouldReturnTrue_whenPassedATokenThatWasGeneratedUsingGetToken(){
		var csrfSvc = _getSvc();
		var token   = csrfSvc.generateToken();
		var i       = 0;

		super.assert( csrfSvc.validateToken( token ) );
	}

	function test04_validateToken_shouldRepeatedlyReturnTrue_whenValidatingAGeneratedTokenWithinItsExpiryLimit(){
		var csrfSvc = _getSvc();
		var token   = csrfSvc.generateToken();

		csrfSvc.validateToken( token );

		super.assert( csrfSvc.validateToken( token ) );
		super.assert( csrfSvc.validateToken( token ) );
		super.assert( csrfSvc.validateToken( token ) );
	}

	function test05_validateToken_shouldReturnFalse_whenPassedARandomInvalidToken(){
		var csrfSvc = _getSvc();
		super.assertFalse( csrfSvc.validateToken( "sometoken" ) );
	}

	function test06_validateToken_shouldReturnFalse_whenPassedTokenHasExpiredDueToTime(){
		var csrfSvc = _getSvc();
		var token   = csrfSvc.generateToken();

		sleep( ( tokenExpiryInSeconds + 1 ) * 1000 ); // milliseconds

		super.assertFalse( csrfSvc.validateToken( token ) );
	}

	function test07_generateToken_shouldReturnSameToken_whenItsTimeoutHasNotExpired(){
		var csrfSvc = _getSvc();
		var token   = csrfSvc.generateToken();

		super.assertEquals( token, csrfSvc.generateToken() );
		super.assertEquals( token, csrfSvc.generateToken() );
		super.assertEquals( token, csrfSvc.generateToken() );
		super.assertEquals( token, csrfSvc.generateToken() );
	}

	function test08_generateToken_shouldReturnANewToken_whenOriginalTokenExpires(){
		var csrfSvc = _getSvc();
		var token   = csrfSvc.generateToken();

		sleep( ( tokenExpiryInSeconds + 1 ) * 1000 ); // milliseconds

		super.assertNotEquals( token, csrfSvc.generateToken() );
	}

	function test09_generateToken_shouldReturnEmptyString_whenAuthenticatedSessionsOnly_andNoUserSession() {
		var csrfSvc = _getSvc( authenticatedSessionOnly=true );

		csrfSvc.$( "$isWebsiteUserLoggedIn", false );
		csrfSvc.$( "$isAdminUserLoggedIn", false );
		csrfSvc.$( "_getToken", {} );

		super.assertEquals( "", csrfSvc.generateToken() );
	}

	function test10_generateToken_shouldReturnToken_whenAuthenticatedSessionsOnly_andNoUserSession_butForceTruePassed() {
		var csrfSvc = _getSvc( authenticatedSessionOnly=true );

		csrfSvc.$( "$isWebsiteUserLoggedIn", false );
		csrfSvc.$( "$isAdminUserLoggedIn", false );
		csrfSvc.$( "_getToken", {} );

		super.assertNotEquals( "", csrfSvc.generateToken( true ) );
	}

	function test11_generateToken_shouldReturnToken_whenAuthenticatedSessionsOnly_andThereIsAUserSession() {
		var csrfSvc = _getSvc( authenticatedSessionOnly=true );

		csrfSvc.$( "$isWebsiteUserLoggedIn", true );
		csrfSvc.$( "$isAdminUserLoggedIn", true );

		super.assertNotEquals( "", csrfSvc.generateToken( true ) );
	}

	function test12_validateToken_shouldReturnTrue_whenSkippingAnonymousRequest() {
		var csrfSvc = _getSvc( authenticatedSessionOnly=true );

		csrfSvc.$( "$isWebsiteUserLoggedIn", false );
		csrfSvc.$( "$isAdminUserLoggedIn", false );
		csrfSvc.$( "_getToken", {} );

		super.assertEquals( true, csrfSvc.validateToken( CreateUUId() ) );
	}

	function test13_validateToken_shouldReturnFalse_whenSkippingAnonymousRequest_butForcePassedWithInvalidToken() {
		var csrfSvc = _getSvc( authenticatedSessionOnly=true );

		csrfSvc.$( "$isWebsiteUserLoggedIn", false );
		csrfSvc.$( "$isAdminUserLoggedIn", false );
		csrfSvc.$( "_getToken", {} );

		super.assertEquals( false, csrfSvc.validateToken( token=CreateUUId(), force=true ) );
	}

	function test14_validateToken_shouldReturnFalse_whenSkippingAnonymousRequest_butRequestNotAnonymousAndHasBadToken() {
		var csrfSvc = _getSvc( authenticatedSessionOnly=true );

		csrfSvc.$( "$isWebsiteUserLoggedIn", false );
		csrfSvc.$( "$isAdminUserLoggedIn", true );
		csrfSvc.$( "_getToken", {} );

		super.assertEquals( false, csrfSvc.validateToken( token=CreateUUId(), force=true ) );
	}

	private function _getSvc(
		  sessionStorage           = sessionStorage
		, tokenExpiryInSeconds     = tokenExpiryInSeconds
		, authenticatedSessionOnly = false
	) {
		return super.createMock( object=new preside.system.services.security.CsrfProtectionService(
			  argumentCollection=arguments
		) );
	}
}

