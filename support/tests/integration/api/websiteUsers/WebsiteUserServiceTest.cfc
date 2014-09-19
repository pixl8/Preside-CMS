component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// tests
	function test01_isLoggedIn_shouldReturnFalse_ifNoUserSessionExistsAndNoRememberMeCookieExists() output=false {
		var userService = _getUserService();

		mockSessionService.$( "exists" ).$args( "website_user" ).$results( false );
		mockCookieService.$( "exists" ).$args( "_presidecms-site-persist" ).$results( false );

		super.assertFalse( userService.isLoggedIn() );
	}

	function test02_isLoggedIn_shouldReturnTrue_whenUserHasActiveSession() output=false {
		var userService = _getUserService();

		mockSessionService.$( "exists" ).$args( "website_user" ).$results( true );

		super.assert( userService.isLoggedIn() );
	}

	function test03_getLoggedInUserDetails_shouldReturnTheDetailsFromSessionStorage() output=false {
		var userService = _getUserService();
		var testUserDetails = { id="some-id", loginid="l33t", emailaddress="myemail address" };

		mockSessionService.$( "getVar" ).$args( name="website_user", default={} ).$results( testUserDetails );

		super.assertEquals( testUserDetails, userService.getLoggedInUserDetails() );
	}

	function test04_getLoggedInUserId_shouldReturnTheIdOFtheCurrentlyLoggedInUser() output=false {
		var userService = _getUserService();
		var testUserDetails = { id="anotherid", loginid="l33t", emailaddress="myemail address" };

		mockSessionService.$( "getVar" ).$args( name="website_user", default={} ).$results( testUserDetails );

		super.assertEquals( testUserDetails.id, userService.getLoggedInUserId() );
	}

	function test05_getLoggedInUserId_shouldReturnAnEmptyStringWhenNoUserIsLoggedIn() output=false {
		var userService = _getUserService();
		var testUserDetails = {};

		mockSessionService.$( "getVar" ).$args( name="website_user", default={} ).$results( testUserDetails );

		super.assertEquals( "", userService.getLoggedInUserId() );
	}

	function test06_logout_shouldDestroyTheUserSession() output=false {
		var userService = _getUserService();

		mockSessionService.$( "deleteVar" ).$args( name="website_user" ).$results( true );

		userService.logout();

		var log = mockSessionService.$calllog().deleteVar;

		super.assertEquals( 1, log.len() );
	}

	function test07_login_shouldReturnFalse_whenUserIdNotFound() output=false {
		var userService = _getUserService();

		userService.$( "isLoggedIn" ).$results( false );
		mockUserDao.$( "selectData" ).$args(
			  filter       = "( login_id = :login_id or email_address = :login_id ) and active = 1"
			, filterParams = { login_id = "dummy" }
			, useCache     = false
			, selectFields = [ "id", "login_id", "email_address", "display_name", "password" ]
		).$results( QueryNew( '' ) );

		super.assertFalse( userService.login( loginId="dummy", password="whatever" ) );
	}

	function test08_login_shouldReturnFalse_whenAlreadyLoggedIn() output=false {
		var userService = _getUserService();

		userService.$( "isLoggedIn" ).$results( true );

		super.assertFalse( userService.login( loginId="dummy", password="whatever" ) );
	}

	function test09_login_shouldReturnFalse_whenUserExistsButPasswordDoesNotMatch() output=false {
		var userService = _getUserService();
		var mockRecord  = QueryNew( 'password', 'varchar', ['blah'] );

		userService.$( "isLoggedIn" ).$results( false );
		mockUserDao.$( "selectData" ).$args(
			  filter       = "( login_id = :login_id or email_address = :login_id ) and active = 1"
			, filterParams = { login_id = "dummy" }
			, useCache     = false
			, selectFields = [ "id", "login_id", "email_address", "display_name", "password" ]
		).$results( mockRecord );
		mockBCryptService.$( "checkpw" ).$args( plainText="whatever", hashed=mockRecord.password ).$results( false );

		super.assertFalse( userService.login( loginId="dummy", password="whatever" ) );
	}

	function test10_login_shouldSetUserDetailsInSessionAndReturnTrue_whenLoginDetailsAreCorrect() output=false {
		var userService        = _getUserService();
		var mockRecord         = QueryNew( 'password,email_address,login_id,id,display_name', 'varchar,varchar,varchar,varchar,varchar', [['blah', 'test@test.com', 'dummy', 'someid', 'test user' ]] );
		var expectedSetVarCall = { name="website_user", value={
			  email_address = mockRecord.email_address
			, display_name  = mockRecord.display_name
			, login_id      = mockRecord.login_id
			, id            = mockRecord.id
		} };

		userService.$( "isLoggedIn" ).$results( false );
		mockUserDao.$( "selectData" ).$args(
			  filter       = "( login_id = :login_id or email_address = :login_id ) and active = 1"
			, filterParams = { login_id = "dummy" }
			, useCache     = false
			, selectFields = [ "id", "login_id", "email_address", "display_name", "password" ]
		).$results( mockRecord );
		mockBCryptService.$( "checkpw" ).$args( plainText="whatever", hashed=mockRecord.password ).$results( true );
		mockSessionService.$( "setVar" );

		super.assert( userService.login( loginId="dummy", password="whatever" ) );

		var sessionServiceCallLog = mockSessionService.$callLog().setVar;

		super.assertEquals( 1, sessionServiceCallLog.len() );

		super.assertEquals( expectedSetVarCall, sessionServiceCallLog[1] );
	}

	function test11_login_shouldSetRememberMeCookieAndTokenRecord_whenRememberLoginIsPassedAsTrue() output=false {
		var userService        = _getUserService();
		var mockRecord         = QueryNew( 'password,email_address,login_id,id,display_name', 'varchar,varchar,varchar,varchar,varchar', [['blah', 'test@test.com', 'dummy', 'someid', 'test user' ]] );
		var uuidRegex         = "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{16}";
		var testSeries        = CreateUUId();
		var testToken         = CreateUUId();
		var testTokenHashed   = "blah";
		var expectedSetVarCall = { name="website_user", value={
			  email_address = mockRecord.email_address
			, display_name  = mockRecord.display_name
			, login_id      = mockRecord.login_id
			, id            = mockRecord.id
		} };

		// mocking
		userService.$( "isLoggedIn" ).$results( false );
		mockUserDao.$( "selectData" ).$args(
			  filter       = "( login_id = :login_id or email_address = :login_id ) and active = 1"
			, filterParams = { login_id = "dummy" }
			, useCache     = false
			, selectFields = [ "id", "login_id", "email_address", "display_name", "password" ]
		).$results( mockRecord );
		mockBCryptService.$( "checkpw" ).$args( plainText="whatever", hashed=mockRecord.password ).$results( true );
		userService.$( "_createNewLoginTokenSeries", testSeries );
		userService.$( "_createNewLoginToken", testToken );
		mockSessionService.$( "setVar" );
		mockUserLoginTokenDao.$( "insertData", CreateUUId() );
		mockCookieService.$( "setVar" );
		mockBCryptService.$( "hashPw" ).$args( testToken ).$results( testTokenHashed );

		// run the login method
		userService.login( loginId="dummy", password="whatever", rememberLogin=true );


		// assertions
		var loginTokenCallLog = mockUserLoginTokenDao.$callLog().insertData;

		super.assertEquals( 1, loginTokenCallLog.len() );
		super.assertEquals( mockRecord.id, loginTokenCallLog[1].data.user );
		super.assertEquals( testTokenHashed, loginTokenCallLog[1].data.token );
		super.assertEquals( testSeries, loginTokenCallLog[1].data.series );

		var cookieServiceCallLog = mockCookieService.$callLog().setVar;

		super.assertEquals( 1, cookieServiceCallLog.len() );
		super.assertEquals( {
			  name     = "_presidecms-site-persist"
			, expires  = 90
			, httpOnly = true
			, value    = { loginId=mockRecord.login_id, expiry=90, series=testSeries, token=testToken }
		}, cookieServiceCallLog[1] );
	}

	function test12_isLoggedIn_shouldReturnTrueAndRefreshLoginToken_whenNoLoginSessionExistsButValidRememberMeCookieDoesExist() output=false {
		var userService         = _getUserService();
		var testUserTokenRecord = QueryNew( 'id,token,user,login_id,email_address,display_name', 'varchar,varchar,varchar,varchar,varchar,varchar', [ [ 'someid', 'hashedToken', 'userid', 'fred', 'test@test.com', 'fred perry' ] ] );
		var testCookie          = { loginId="fred", expiry=20, series="someseries", token="sometoken" };
		var newToken            = CreateUUId();

		StructDelete( request, "_presideWebsiteAutoLoginResult" );

		// mocking
		mockSessionService.$( "exists" ).$args( "website_user" ).$results( false );
		mockCookieService.$( "exists" ).$args( "_presidecms-site-persist" ).$results( true );
		mockCookieService.$( "getVar" ).$args( "_presidecms-site-persist", {} ).$results( testCookie );
		mockUserLoginTokenDao.$( "selectData" ).$args(
			  selectFields = [ "website_user_login_token.id", "website_user_login_token.token", "website_user_login_token.user", "website_user.login_id", "website_user.email_address", "website_user.display_name" ]
			, filter       = { series = testCookie.series }
		).$results( testUserTokenRecord );
		mockUserLoginTokenDao.$( "updateData", true );
		mockBCryptService.$( "checkPw" ).$args( testCookie.token, testUserTokenRecord.token ).$results( true );
		mockCookieService.$( "setVar" );
		mockSessionService.$( "setVar" );
		mockBCryptService.$( "hashPw" ).$args( newToken ).$results( "reHashedToken" );
		userService.$( "_createNewLoginToken", newToken );

		// assertions
		super.assert( userService.isLoggedIn() );
		var updateDataCallLog = mockUserLoginTokenDao.$callLog().updateData;
		var setCookieCallLog = mockCookieService.$callLog().setVar;
		var hashTokenCallLog = mockBCryptService.$callLog().hashPw;
		var setSessionCallLog = mockSessionService.$callLog().setVar;

		super.assertEquals( 1, updateDataCallLog.len() );
		super.assertEquals( { id=testUserTokenRecord.id, data={ token="reHashedToken" } }, updateDataCallLog[1] );

		super.assertEquals( 1, setCookieCallLog.len() );
		super.assertEquals( "_presidecms-site-persist", setCookieCallLog[1].name ?: "" );
		super.assertEquals( true                      , setCookieCallLog[1].httpOnly ?: "" );
		super.assertEquals( testCookie.expiry         , setCookieCallLog[1].expires  ?: "" );
		super.assertEquals( { loginId=testCookie.loginId, expiry=testCookie.expiry, series=testCookie.series, token=newToken }, setCookieCallLog[1].value  ?: {} );

		super.assertEquals( 1, setSessionCallLog.len() );
		super.assertEquals({ name="website_user", value={
			  email_address = testUserTokenRecord.email_address
			, display_name  = testUserTokenRecord.display_name
			, login_id      = testUserTokenRecord.login_id
			, id            = testUserTokenRecord.user
		} }, setSessionCallLog[1] );

		super.assertEquals( 1, hashTokenCallLog.len() );
	}

	function test13_isLoggedIn_shouldTakeAlertAndSecurityMeasures_whenLoginCookieHasCorrectDetailsExceptForItsToken() output=false {
		var userService         = _getUserService();
		var testUserTokenRecord = QueryNew( 'id,token,user,login_id,email_address,display_name', 'varchar,varchar,varchar,varchar,varchar,varchar', [ [ 'someid', 'hashedToken', 'userid', 'fred', 'test@test.com', 'fred perry' ] ] );
		var testCookie          = { loginId="fred", expiry=20, series="someseries", token="sometoken" };
		var alertThrown         = false;
		var testAlertClosure    = function(){ alertThrown = true };

		StructDelete( request, "_presideWebsiteAutoLoginResult" );

		// mocking
		mockSessionService.$( "exists" ).$args( "website_user" ).$results( false );
		mockCookieService.$( "exists" ).$args( "_presidecms-site-persist" ).$results( true );
		mockCookieService.$( "getVar" ).$args( "_presidecms-site-persist", {} ).$results( testCookie );
		mockUserLoginTokenDao.$( "selectData" ).$args(
			  selectFields = [ "website_user_login_token.id", "website_user_login_token.token", "website_user_login_token.user", "website_user.login_id", "website_user.email_address", "website_user.display_name" ]
			, filter       = { series = testCookie.series }
		).$results( testUserTokenRecord );
		mockBCryptService.$( "checkPw" ).$args( testCookie.token, testUserTokenRecord.token ).$results( false );
		mockCookieService.$( "deleteVar" ).$args( "_presidecms-site-persist" ).$results( true );
		mockUserLoginTokenDao.$( "deleteData" );

		// assertions
		super.assertFalse( userService.isLoggedIn( securityAlertCallback=testAlertClosure ) );

		var cookieDeleteLog = mockCookieService.$callLog().deleteVar;
		super.assertEquals( 1, cookieDeleteLog.len() );

		var tokenDeleteLog = mockUserLoginTokenDao.$callLog().deleteData;
		super.assertEquals( 1, tokenDeleteLog.len() );
		super.assertEquals( { id=testUserTokenRecord.id }, tokenDeleteLog[1] );

		super.assert( alertThrown );
	}



// private helpers
	private any function _getUserService() output=false {
		mockSessionService    = getMockbox().createEmptyMock( "preside.system.services.cfmlScopes.SessionService" );
		mockCookieService     = getMockbox().createEmptyMock( "preside.system.services.cfmlScopes.CookieService" );
		mockUserDao           = getMockbox().createStub();
		mockUserLoginTokenDao = getMockbox().createStub();
		mockBCryptService     = getMockBox().createEmptyMock( "preside.system.services.encryption.bcrypt.BCryptService" );

		return getMockBox().createMock( object= new preside.system.services.websiteUsers.WebsiteUserService(
			  sessionService    = mockSessionService
			, cookieService     = mockCookieService
			, userDao           = mockUserDao
			, userLoginTokenDao = mockUserLoginTokenDao
			, bcryptService     = mockBCryptService
		) );
	}

}