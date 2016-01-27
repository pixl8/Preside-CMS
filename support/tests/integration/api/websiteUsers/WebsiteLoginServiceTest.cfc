component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// tests
	function test01_isLoggedIn_shouldReturnFalse_ifNoUserSessionExistsAndNoRememberMeCookieExists() output=false {
		var userService = _getUserService();

		mockSessionStorage.$( "exists" ).$args( "website_user" ).$results( false );
		mockCookieService.$( "exists" ).$args( "_presidecms-site-persist" ).$results( false );

		super.assertFalse( userService.isLoggedIn() );
	}

	function test02_isLoggedIn_shouldReturnTrue_whenUserHasActiveSession() output=false {
		var userService = _getUserService();

		mockSessionStorage.$( "exists" ).$args( "website_user" ).$results( true );

		super.assert( userService.isLoggedIn() );
	}

	function test03_getLoggedInUserDetails_shouldReturnTheDetailsFromSessionStorage() output=false {
		var userService = _getUserService();
		var testUserDetails = { id="some-id", loginid="l33t", emailaddress="myemail address" };

		mockSessionStorage.$( "getVar" ).$args( name="website_user", default={} ).$results( testUserDetails );

		super.assertEquals( testUserDetails, userService.getLoggedInUserDetails() );
	}

	function test04_getLoggedInUserId_shouldReturnTheIdOFtheCurrentlyLoggedInUser() output=false {
		var userService = _getUserService();
		var testUserDetails = { id="anotherid", loginid="l33t", emailaddress="myemail address" };

		mockSessionStorage.$( "getVar" ).$args( name="website_user", default={} ).$results( testUserDetails );

		super.assertEquals( testUserDetails.id, userService.getLoggedInUserId() );
	}

	function test05_getLoggedInUserId_shouldReturnAnEmptyStringWhenNoUserIsLoggedIn() output=false {
		var userService = _getUserService();
		var testUserDetails = {};

		mockSessionStorage.$( "getVar" ).$args( name="website_user", default={} ).$results( testUserDetails );

		super.assertEquals( "", userService.getLoggedInUserId() );
	}

	function test06_logout_shouldDestroyTheUserSession() output=false {
		var userService = _getUserService();

		mockSessionStorage.$( "deleteVar" ).$args( name="website_user" ).$results( true );
		mockCookieService.$( "exists", false );
		userService.$( "recordLogout", true );
		userService.logout();

		var log = mockSessionStorage.$calllog().deleteVar;

		super.assertEquals( 1, log.len() );
	}

	function test06_01_logout_shouldRecordTheLogout() output=false {
		var userService = _getUserService();

		mockSessionStorage.$( "deleteVar" ).$args( name="website_user" ).$results( true );
		mockCookieService.$( "exists", false );
		userService.$( "recordLogout", true );
		userService.logout();

		var log = userService.$calllog().recordLogout;

		super.assertEquals( 1, log.len() );
	}

	function test07_login_shouldReturnFalse_whenUserIdNotFound() output=false {
		var userService = _getUserService();

		userService.$( "isLoggedIn" ).$results( false );
		mockUserDao.$( "selectData" ).$args(
			  filter       = "( login_id = :login_id or email_address = :login_id ) and active = '1'"
			, filterParams = { login_id = "dummy" }
			, useCache     = false
		).$results( QueryNew( '' ) );

		super.assertFalse( userService.login( loginId="dummy", password="whatever" ) );
	}

	function test08_login_shouldReturnFalse_whenAlreadyLoggedIn() output=false {
		var userService = _getUserService();

		userService.$( "isLoggedIn" ).$results( true );
		userService.$( "isAutoLoggedIn" ).$results( false );

		super.assertFalse( userService.login( loginId="dummy", password="whatever" ) );
	}

	function test09_login_shouldReturnFalse_whenUserExistsButPasswordDoesNotMatch() output=false {
		var userService = _getUserService();
		var mockRecord  = QueryNew( 'password', 'varchar', ['blah'] );

		userService.$( "isLoggedIn" ).$results( false );
		mockUserDao.$( "selectData" ).$args(
			  filter       = "( login_id = :login_id or email_address = :login_id ) and active = '1'"
			, filterParams = { login_id = "dummy" }
			, useCache     = false
		).$results( mockRecord );
		mockBCryptService.$( "checkpw" ).$args( plainText="whatever", hashed=mockRecord.password ).$results( false );

		super.assertFalse( userService.login( loginId="dummy", password="whatever" ) );
	}

	function test10_login_shouldSetUserDetailsInSessionAndReturnTrue_whenLoginDetailsAreCorrect() output=false {
		var userService        = _getUserService();
		var mockRecord         = QueryNew( 'password,email_address,login_id,id,display_name', 'varchar,varchar,varchar,varchar,varchar', [['blah', 'test@test.com', 'dummy', 'someid', 'test user' ]] );
		var expectedSetVarCall = { name="website_user", value={
			  email_address         = mockRecord.email_address
			, display_name          = mockRecord.display_name
			, login_id              = mockRecord.login_id
			, id                    = mockRecord.id
			, password              = "blah"
			, session_authenticated = true
		} };

		userService.$( "isLoggedIn" ).$results( false );
		userService.$( "recordLogin" ).$results( true );
		mockUserDao.$( "selectData" ).$args(
			  filter       = "( login_id = :login_id or email_address = :login_id ) and active = '1'"
			, filterParams = { login_id = "dummy" }
			, useCache     = false
		).$results( mockRecord );
		mockBCryptService.$( "checkpw" ).$args( plainText="whatever", hashed=mockRecord.password ).$results( true );
		mockSessionStorage.$( "setVar" );

		super.assert( userService.login( loginId="dummy", password="whatever" ) );

		var sessionStorageCallLog = mockSessionStorage.$callLog().setVar;

		super.assertEquals( 1, sessionStorageCallLog.len() );
		super.assertEquals( expectedSetVarCall, sessionStorageCallLog[1] );
	}

	function test11_login_shouldSetRememberMeCookieAndTokenRecord_whenRememberLoginIsPassedAsTrue() output=false {
		var userService        = _getUserService();
		var mockRecord         = QueryNew( 'password,email_address,login_id,id,display_name', 'varchar,varchar,varchar,varchar,varchar', [['blah', 'test@test.com', 'dummy', 'someid', 'test user' ]] );
		var uuidRegex         = "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{16}";
		var testSeries        = CreateUUId();
		var testToken         = CreateUUId();
		var testTokenHashed   = "blah";

		// mocking
		userService.$( "isLoggedIn" ).$results( false );
		userService.$( "recordLogin" ).$results( true );
		mockUserDao.$( "selectData" ).$args(
			  filter       = "( login_id = :login_id or email_address = :login_id ) and active = '1'"
			, filterParams = { login_id = "dummy" }
			, useCache     = false
		).$results( mockRecord );
		mockBCryptService.$( "checkpw" ).$args( plainText="whatever", hashed=mockRecord.password ).$results( true );
		userService.$( "_createNewLoginTokenSeries", testSeries );
		userService.$( "_createNewLoginToken", testToken );
		mockSessionStorage.$( "setVar" );
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
		var mockRecord         = QueryNew( 'password,email_address,login_id,id,display_name', 'varchar,varchar,varchar,varchar,varchar', [['blah', 'test@test.com', 'dummy', 'someid', 'test user' ]] );
		var testCookie          = { loginId="fred", expiry=20, series="someseries", token="sometoken" };
		var newToken            = CreateUUId();

		StructDelete( request, "_presideWebsiteAutoLoginResult" );

		// mocking
		mockSessionStorage.$( "exists" ).$args( "website_user" ).$results( false );
		mockCookieService.$( "exists" ).$args( "_presidecms-site-persist" ).$results( true );
		mockCookieService.$( "getVar" ).$args( "_presidecms-site-persist", {} ).$results( testCookie );
		mockUserLoginTokenDao.$( "selectData" ).$args(
			  selectFields = [ "website_user_login_token.id", "website_user_login_token.token", "website_user.login_id" ]
			, filter       = { series = testCookie.series }
		).$results( testUserTokenRecord );
		mockUserLoginTokenDao.$( "updateData", true );
		mockBCryptService.$( "checkPw" ).$args( testCookie.token, testUserTokenRecord.token ).$results( true );
		mockCookieService.$( "setVar" );
		mockSessionStorage.$( "setVar" );
		mockBCryptService.$( "hashPw" ).$args( newToken ).$results( "reHashedToken" );
		mockUserDao.$( "selectData" ).$args(
			  filter       = "( login_id = :login_id or email_address = :login_id ) and active = '1'"
			, filterParams = { login_id = "fred" }
			, useCache     = false
		).$results( mockRecord );

		userService.$( "_createNewLoginToken", newToken );

		// assertions
		super.assert( userService.isLoggedIn() );
		var updateDataCallLog = mockUserLoginTokenDao.$callLog().updateData;
		var setCookieCallLog = mockCookieService.$callLog().setVar;
		var hashTokenCallLog = mockBCryptService.$callLog().hashPw;
		var setSessionCallLog = mockSessionStorage.$callLog().setVar;

		super.assertEquals( 1, updateDataCallLog.len() );
		super.assertEquals( { id=testUserTokenRecord.id, data={ token="reHashedToken" } }, updateDataCallLog[1] );

		super.assertEquals( 1, setCookieCallLog.len() );
		super.assertEquals( "_presidecms-site-persist", setCookieCallLog[1].name ?: "" );
		super.assertEquals( true                      , setCookieCallLog[1].httpOnly ?: "" );
		super.assertEquals( testCookie.expiry         , setCookieCallLog[1].expires  ?: "" );
		super.assertEquals( { loginId=testCookie.loginId, expiry=testCookie.expiry, series=testCookie.series, token=newToken }, setCookieCallLog[1].value  ?: {} );

		super.assertEquals( 1, setSessionCallLog.len() );
		super.assertEquals({ name="website_user", value={
			  email_address         = mockRecord.email_address
			, display_name          = mockRecord.display_name
			, login_id              = mockRecord.login_id
			, id                    = mockRecord.id
			, password              = mockRecord.password
			, session_authenticated = false
		} }, setSessionCallLog[1] );

		super.assertEquals( 1, hashTokenCallLog.len() );
	}

	function test13_isLoggedIn_shouldTakeAlertAndSecurityMeasures_whenLoginCookieHasCorrectDetailsExceptForItsToken() output=false {
		var userService         = _getUserService();
		var testUserTokenRecord = QueryNew( 'id,token,user,login_id,email_address,display_name', 'varchar,varchar,varchar,varchar,varchar,varchar', [ [ 'someid', 'hashedToken', 'userid', 'fred', 'test@test.com', 'fred perry' ] ] );
		var mockRecord          = QueryNew( 'password,email_address,login_id,id,display_name', 'varchar,varchar,varchar,varchar,varchar', [['blah', 'test@test.com', 'dummy', 'someid', 'test user' ]] );
		var testCookie          = { loginId="fred", expiry=20, series="someseries", token="sometoken" };
		var alertThrown         = false;
		var testAlertClosure    = function(){ alertThrown = true };

		StructDelete( request, "_presideWebsiteAutoLoginResult" );

		// mocking
		mockSessionStorage.$( "exists" ).$args( "website_user" ).$results( false );
		mockCookieService.$( "exists" ).$args( "_presidecms-site-persist" ).$results( true );
		mockCookieService.$( "getVar" ).$args( "_presidecms-site-persist", {} ).$results( testCookie );
		mockUserLoginTokenDao.$( "selectData" ).$args(
			  selectFields = [ "website_user_login_token.id", "website_user_login_token.token", "website_user.login_id" ]
			, filter       = { series = testCookie.series }
		).$results( testUserTokenRecord );
		mockBCryptService.$( "checkPw" ).$args( testCookie.token, testUserTokenRecord.token ).$results( false );
		mockCookieService.$( "deleteVar" ).$args( "_presidecms-site-persist" ).$results( true );
		mockUserLoginTokenDao.$( "deleteData" );
		mockUserDao.$( "selectData" ).$args(
			  filter       = "( login_id = :login_id or email_address = :login_id ) and active = '1'"
			, filterParams = { login_id = "fred" }
			, useCache     = false
		).$results( mockRecord );

		// assertions
		super.assertFalse( userService.isLoggedIn( securityAlertCallback=testAlertClosure ) );

		var cookieDeleteLog = mockCookieService.$callLog().deleteVar;
		super.assertEquals( 1, cookieDeleteLog.len() );

		var tokenDeleteLog = mockUserLoginTokenDao.$callLog().deleteData;
		super.assertEquals( 1, tokenDeleteLog.len() );
		super.assertEquals( { id=testUserTokenRecord.id }, tokenDeleteLog[1] );

		super.assert( alertThrown );
	}

	function test14_logout_shouldDestroyRememberMeCookieAndTokenDbRecord_whenCookieExists() output=false {
		var userService = _getUserService();
		var testCookieValue = { loginId="joyce", expiry=60, series=CreateUUId(), token=CreateUUId() };

		mockSessionStorage.$( "deleteVar" ).$args( name="website_user" ).$results( true );
		mockCookieService.$( "exists", true );
		mockCookieService.$( "getVar" ).$args( "_presidecms-site-persist", {} ).$results( testCookieValue );
		mockCookieService.$( "deleteVar" ).$args( "_presidecms-site-persist" ).$results( true );
		mockUserLoginTokenDao.$( "deleteData" ).$args( filter={ series=testCookieValue.series } ).$results( true );
		userService.$( "recordLogout" ).$results( true );

		userService.logout();

		super.assertEquals( 1, mockSessionStorage.$calllog().deleteVar.len() );
		super.assertEquals( 1, mockCookieService.$calllog().exists.len() );
		super.assertEquals( 1, mockCookieService.$calllog().deleteVar.len() );
		super.assertEquals( 1, mockUserLoginTokenDao.$calllog().deleteData.len() );
	}

	function test15_isAutoLoggedIn_shouldReturnTrue_whenUserHasBeenAutoLoggedInWithCookie() output=false {
		var userService = _getUserService();

		mockSessionStorage.$( "exists", true );
		userService.$( "getLoggedInUserDetails", {
			  id                    = CreateUUId()
			, login_id              = "hamster"
			, email_address         = "test@test.com"
			, display_name          = "Test Hamster"
			, session_authenticated = false
		} );

		super.assert( userService.isAutoLoggedIn() );
	}

	function test16_sendPasswordResetInstructions_shouldReturnFalseWhenPassedLoginIdDoesNotExist() output=false {
		var userService = _getUserService();
		var testLoginId = "watson.dominic@gmail.com";

		userService.$( "_getUserByLoginId" ).$args( testLoginId ).$results( {} );

		super.assertFalse( userService.sendPasswordResetInstructions( testLoginId ) );
	}

	function test17_sendPasswordResetInstructions_shouldGenerateTemporaryResetTokenAndSendEmailToUser() output=false {
		var userService       = _getUserService();
		var testLoginId       = "M131654131";
		var testUserRecord    = { id=CreateUUId(), email_address='dom@test.com', display_name="My dominic sir", login_id="domwatson" };
		var testTempToken     = CreateUUId();
		var testTempKey       = CreateUUId();
		var testTempKeyHashed = CreateUUId();
		var testExpiryDate    = Now();

		userService.$( "_getUserByLoginId" ).$args( testLoginId ).$results( testUserRecord );
		userService.$( "_createTemporaryResetToken", testTempToken );
		userService.$( "_createTemporaryResetKey", testTempKey );
		userService.$( "_createTemporaryResetTokenExpiry", testExpiryDate );
		mockBCryptService.$( "hashpw" ).$args( testTempKey ).$results( testTempKeyHashed );
		mockEmailService.$( "send" ).$args(
			  template = "resetWebsitePassword"
			, to       = [ testUserRecord.email_address ]
			, args     = { resetToken = testTempToken & "-" & testTempKey, expires=testExpiryDate, username=testUserRecord.display_name, loginid=testUserRecord.login_id }
		).$results( true );
		mockUserDao.$( "updateData" ).$args(
			  id   = testUserRecord.id
			, data = { reset_password_token=testTempToken, reset_password_key=testTempKeyHashed, reset_password_token_expiry=testExpiryDate }
		).$results( true );

		super.assert( userService.sendPasswordResetInstructions( testLoginId ) );
		super.assertEquals( 1, mockUserDao.$callLog().updateData.len() );
		super.assertEquals( 1, mockEmailService.$callLog().send.len() );
	}

	function test18_validateResetPasswordToken_shouldReturnFalse_whenTokenRecordNotFound() output=false {
		var userService = _getUserService();
		var testToken   = "xxxxxx-yyyyyy";

		mockUserDao.$( "selectData" ).$args(
			  filter       = { reset_password_token = ListFirst( testToken, "-" ) }
			, selectFields = [ "id", "reset_password_key", "reset_password_token_expiry" ]
		).$results( QueryNew('') );

		super.assertFalse( userService.validateResetPasswordToken( testToken ) );
	}

	function test19_validateResetPasswordToken_shouldReturnFalseAndClearToken_whenRecordFoundButTokenHasExpired() output=false {
		var userService = _getUserService();
		var testToken   = "xxxxxx-yyyyyy";
		var testRecord  = QueryNew('id,reset_password_key,reset_password_token_expiry', 'varchar,varchar,date', [[ "someid", "hashedkey", DateAdd( "d", -1, Now() ) ]]);

		mockUserDao.$( "selectData" ).$args(
			  filter       = { reset_password_token = ListFirst( testToken, "-" ) }
			, selectFields = [ "id", "reset_password_key", "reset_password_token_expiry" ]
		).$results( testRecord );

		mockUserDao.$( "updateData" ).$args(
			  id     = testRecord.id
			, data   = { reset_password_token="", reset_password_key="", reset_password_token_expiry="" }
		).$results( true );

		super.assertFalse( userService.validateResetPasswordToken( testToken ) );
		super.assertEquals( 1, mockUserDao.$callLog().updateData.len() )
	}

	function test20_validateResetPasswordToken_shouldReturnFalseAndClearToken_whenRecordFoundAndNotExipiredByHashedKeyDoesNotMatch() output=false {
		var userService = _getUserService();
		var testToken   = "xxxxxx-yyyyyy";
		var testRecord  = QueryNew('id,reset_password_key,reset_password_token_expiry', 'varchar,varchar,date', [[ "someid", "hashedkey", DateAdd( "d", +1, Now() ) ]]);

		mockUserDao.$( "selectData" ).$args(
			  filter       = { reset_password_token = ListFirst( testToken, "-" ) }
			, selectFields = [ "id", "reset_password_key", "reset_password_token_expiry" ]
		).$results( testRecord );

		mockUserDao.$( "updateData" ).$args(
			  id     = testRecord.id
			, data   = { reset_password_token="", reset_password_key="", reset_password_token_expiry="" }
		).$results( true );

		mockBCryptService.$( "checkPw" ).$args( ListLast( testToken, "-" ), testRecord.reset_password_key ).$results( false );

		super.assertFalse( userService.validateResetPasswordToken( testToken ) );
		super.assertEquals( 1, mockUserDao.$callLog().updateData.len() )
	}

	function test21_validateResetPasswordToken_shouldReturnTrue_whenRecordFoundAndNotExipiredAndHashedKeyMatches() output=false {
		var userService = _getUserService();
		var testToken   = "xxxxxx-yyyyyy";
		var testRecord  = QueryNew('id,reset_password_key,reset_password_token_expiry', 'varchar,varchar,date', [[ "someid", "hashedkey", DateAdd( "d", +1, Now() ) ]]);

		mockUserDao.$( "selectData" ).$args(
			  filter       = { reset_password_token = ListFirst( testToken, "-" ) }
			, selectFields = [ "id", "reset_password_key", "reset_password_token_expiry" ]
		).$results( testRecord );

		mockBCryptService.$( "checkPw" ).$args( ListLast( testToken, "-" ), testRecord.reset_password_key ).$results( true );

		super.assert( userService.validateResetPasswordToken( testToken ) );
	}

	function test22_resetPassword_shouldReturnFalseAndDoNothing_whenTokenRecordNotFound() output=false {
		var userService = _getUserService();
		var testToken   = "xxxxxx-yyyyyy";

		userService.$( "_getUserRecordByPasswordResetToken" ).$args( testToken ).$results( QueryNew('') );

		super.assertFalse( userService.resetPassword( testToken, "somePassword" ) );
	}

	function test23_resetPassword_shouldSetEncryptedPasswordAndClearTokens_whenTokenRecordFount() output=false {
		var userService       = _getUserService();
		var testToken         = "xxxxxx-yyyyyy";
		var testRecord        = QueryNew( 'id', 'varchar', [[CreateUUId()]] );
		var plainPassword     = CreateUUId();
		var encryptedPassword = CreateUUId();

		userService.$( "_getUserRecordByPasswordResetToken" ).$args( testToken ).$results( testRecord );
		mockBCryptService.$( "hashPw" ).$args( plainPassword ).$results( encryptedPassword );
		mockUserDao.$( "updateData" ).$args(
			  id     = testRecord.id
			, data   = { password=encryptedPassword, reset_password_token="", reset_password_key="", reset_password_token_expiry="" }
		).$results( true );

		super.assert( userService.resetPassword( testToken, plainPassword ) );
		super.assertEquals( 1, mockUserDao.$callLog().updateData.len() )
	}



// private helpers
	private any function _getUserService() output=false {
		mockSessionStorage    = getMockbox().createEmptyMock( "coldbox.system.plugins.SessionStorage" );
		mockCookieService     = getMockbox().createEmptyMock( "preside.system.services.cfmlScopes.CookieService" );
		mockUserDao           = getMockbox().createStub();
		mockUserLoginTokenDao = getMockbox().createStub();
		mockBCryptService     = getMockBox().createEmptyMock( "preside.system.services.encryption.bcrypt.BCryptService" );
		mockSysConfigService  = getMockBox().createEmptyMock( "preside.system.services.configuration.SystemConfigurationService" );
		mockEmailService      = getMockBox().createEmptyMock( "preside.system.services.email.EmailService" );

		return getMockBox().createMock( object= new preside.system.services.websiteUsers.WebsiteLoginService(
			  sessionStorage             = mockSessionStorage
			, cookieService              = mockCookieService
			, userDao                    = mockUserDao
			, userLoginTokenDao          = mockUserLoginTokenDao
			, bcryptService              = mockBCryptService
			, systemConfigurationService = mockSysConfigService
			, emailService               = mockEmailService
		) );
	}

}