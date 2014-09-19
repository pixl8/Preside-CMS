component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// tests
	function test01_isLoggedIn_shouldReturnFalse_ifNoUserSessionExists() output=false {
		var userService = _getUserService();

		mockSessionService.$( "exists" ).$args( "website_user" ).$results( false );

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
		var expectedSetVarCall = { name="website_user", value={
			  email_address = mockRecord.email_address
			, display_name  = mockRecord.display_name
			, login_id      = mockRecord.login_id
			, id            = mockRecord.id
		} };
		var uuidRegex          = "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{16}";

		// mocking
		userService.$( "isLoggedIn" ).$results( false );
		mockUserDao.$( "selectData" ).$args(
			  filter       = "( login_id = :login_id or email_address = :login_id ) and active = 1"
			, filterParams = { login_id = "dummy" }
			, useCache     = false
			, selectFields = [ "id", "login_id", "email_address", "display_name", "password" ]
		).$results( mockRecord );
		mockBCryptService.$( "checkpw" ).$args( plainText="whatever", hashed=mockRecord.password ).$results( true );
		mockSessionService.$( "setVar" );
		mockUserLoginTokenDao.$( "insertData", CreateUUId() );
		mockCookieService.$( "setVar" );
		mockBCryptService.$( "hashPw", "hashedToken" );


		// run the login method
		userService.login( loginId="dummy", password="whatever", rememberLogin=true );


		// assertions
		var loginTokenCallLog = mockUserLoginTokenDao.$callLog().insertData;

		super.assertEquals( 1, loginTokenCallLog.len() );
		super.assertEquals( mockRecord.id, loginTokenCallLog[1].data.user );
		super.assertEquals( "hashedToken", loginTokenCallLog[1].data.token );
		super.assert( ReFindNoCase( uuidRegex, loginTokenCallLog[1].data.series ) );

		var cookieServiceCallLog = mockCookieService.$callLog().setVar;

		super.assertEquals( 1                         , cookieServiceCallLog.len() );
		super.assertEquals( "_presidecms-site-persist", cookieServiceCallLog[1].name ?: "" );
		super.assertEquals( true                      , cookieServiceCallLog[1].httpOnly ?: "" );
		super.assertEquals( "90"                      , cookieServiceCallLog[1].expires  ?: "" );
		super.assert( ReFindNoCase( "^dummy\s#loginTokenCallLog[1].data.series#\s#uuidRegex#", cookieServiceCallLog[1].value ) );

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