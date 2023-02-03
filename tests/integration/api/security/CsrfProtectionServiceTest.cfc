component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// SETUP, etc
	function setup() {
		variables.tokenExpiryInSeconds = 5;
		variables.sessionStorage       = new tests.resources.HelperObjects.TestSessionStorage();
		variables.csrfSvc              = new preside.system.services.security.CsrfProtectionService(
			  sessionStorage       = sessionStorage
			, tokenExpiryInSeconds = tokenExpiryInSeconds
		);
	}

// TESTS
	function test01_generateToken_shouldReturnARandomlyGeneratedToken(){
		super.assert( Len( csrfSvc.generateToken() ) );
	}

	function test02_validateToken_shouldReturnFalse_whenNoCallToGenerateATokenHasBeenMade(){
		super.assertFalse( csrfSvc.validateToken( CreateUUId() ) );
	}

	function test03_validateToken_shouldReturnTrue_whenPassedATokenThatWasGeneratedUsingGetToken(){
		var token = csrfSvc.generateToken();
		var i     = 0;

		super.assert( csrfSvc.validateToken( token ) );
	}

	function test04_validateToken_shouldRepeatedlyReturnTrue_whenValidatingAGeneratedTokenWithinItsExpiryLimit(){
		var token = csrfSvc.generateToken();

		csrfSvc.validateToken( token );

		super.assert( csrfSvc.validateToken( token ) );
		super.assert( csrfSvc.validateToken( token ) );
		super.assert( csrfSvc.validateToken( token ) );
	}

	function test05_validateToken_shouldReturnFalse_whenPassedARandomInvalidToken(){
		super.assertFalse( csrfSvc.validateToken( "sometoken" ) );
	}

	function test06_validateToken_shouldReturnFalse_whenPassedTokenHasExpiredDueToTime(){
		var token = csrfSvc.generateToken();

		sleep( ( tokenExpiryInSeconds + 1 ) * 1000 ); // milliseconds

		super.assertFalse( csrfSvc.validateToken( token ) );
	}

	function test07_generateToken_shouldReturnSameToken_whenItsTimeoutHasNotExpired(){
		var token = csrfSvc.generateToken();

		super.assertEquals( token, csrfSvc.generateToken() );
		super.assertEquals( token, csrfSvc.generateToken() );
		super.assertEquals( token, csrfSvc.generateToken() );
		super.assertEquals( token, csrfSvc.generateToken() );
	}

	function test08_generateToken_shouldReturnANewToken_whenOriginalTokenExpires(){
		var token = csrfSvc.generateToken();

		sleep( ( tokenExpiryInSeconds + 1 ) * 1000 ); // milliseconds

		super.assertNotEquals( token, csrfSvc.generateToken() );
	}

}

