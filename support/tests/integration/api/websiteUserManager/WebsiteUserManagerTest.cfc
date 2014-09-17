component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// tests
	function test01_isLoggedIn_shouldReturnFalse_ifNoUserSessionExists() output=false {
		var userManager = _getUserManager();

		mockSessionService.$( "exists" ).$args( "website_user" ).$results( false );

		super.assertFalse( userManager.isLoggedIn() );
	}

	function test02_isLoggedIn_shouldReturnTrue_whenUserHasActiveSession() output=false {
		var userManager = _getUserManager();

		mockSessionService.$( "exists" ).$args( "website_user" ).$results( true );

		super.assert( userManager.isLoggedIn() );
	}

	function test03_getLoggedInUserDetails_shouldReturnTheDetailsFromSessionStorage() output=false {
		var userManager = _getUserManager();
		var testUserDetails = { id="some-id", loginid="l33t", emailaddress="myemail address" };

		mockSessionService.$( "getVar" ).$args( name="website_user", default={} ).$results( testUserDetails );

		super.assertEquals( testUserDetails, userManager.getLoggedInUserDetails() );
	}

	function test04_getLoggedInUserId_shouldReturnTheIdOFtheCurrentlyLoggedInUser() output=false {
		var userManager = _getUserManager();
		var testUserDetails = { id="anotherid", loginid="l33t", emailaddress="myemail address" };

		mockSessionService.$( "getVar" ).$args( name="website_user", default={} ).$results( testUserDetails );

		super.assertEquals( testUserDetails.id, userManager.getLoggedInUserId() );
	}

	function test05_getLoggedInUserId_shouldReturnAnEmptyStringWhenNoUserIsLoggedIn() output=false {
		var userManager = _getUserManager();
		var testUserDetails = {};

		mockSessionService.$( "getVar" ).$args( name="website_user", default={} ).$results( testUserDetails );

		super.assertEquals( "", userManager.getLoggedInUserId() );
	}

	function test06_logout_shouldDestroyTheUserSession() output=false {
		var userManager = _getUserManager();

		mockSessionService.$( "deleteVar" ).$args( name="website_user" ).$results( true );

		userManager.logout();

		var log = mockSessionService.$calllog().deleteVar;

		super.assertEquals( 1, log.len() );
	}

	function test07_login_shouldReturnFalse_whenUserIdNotFound() output=false {
		var userManager = _getUserManager();

		userManager.$( "isLoggedIn" ).$results( false );
		mockUserDao.$( "selectData" ).$args(
			  filter       = "( login_id = :login_id or email_address = :login_id ) and active = 1"
			, filterParams = { login_id = "dummy" }
			, useCache     = false
			, selectFields = [ "id", "login_id", "email_address", "display_name", "password" ]
		).$results( QueryNew( '' ) );

		super.assertFalse( userManager.login( loginId="dummy", password="whatever" ) );
	}

	function test08_login_shouldReturnFalse_whenAlreadyLoggedIn() output=false {
		var userManager = _getUserManager();

		userManager.$( "isLoggedIn" ).$results( true );

		super.assertFalse( userManager.login( loginId="dummy", password="whatever" ) );
	}

	function test09_login_shouldReturnFalse_whenUserExistsButPasswordDoesNotMatch() output=false {
		var userManager = _getUserManager();
		var mockRecord  = QueryNew( 'password', 'varchar', ['blah'] );

		userManager.$( "isLoggedIn" ).$results( false );
		mockUserDao.$( "selectData" ).$args(
			  filter       = "( login_id = :login_id or email_address = :login_id ) and active = 1"
			, filterParams = { login_id = "dummy" }
			, useCache     = false
			, selectFields = [ "id", "login_id", "email_address", "display_name", "password" ]
		).$results( mockRecord );
		mockBCryptService.$( "checkpw" ).$args( plainText="whatever", hashed=mockRecord.password ).$results( false );

		super.assertFalse( userManager.login( loginId="dummy", password="whatever" ) );
	}

	function test10_login_shouldSetUserDetailsInSessionAndReturnTrue_whenLoginDetailsAreCorrect() output=false {
		var userManager        = _getUserManager();
		var mockRecord         = QueryNew( 'password,email_address,login_id,id,display_name', 'varchar,varchar,varchar,varchar,varchar', [['blah', 'test@test.com', 'dummy', 'someid', 'test user' ]] );
		var expectedSetVarCall = { name="website_user", value={
			  email_address = mockRecord.email_address
			, display_name  = mockRecord.display_name
			, login_id      = mockRecord.login_id
			, id            = mockRecord.id
		} };

		userManager.$( "isLoggedIn" ).$results( false );
		mockUserDao.$( "selectData" ).$args(
			  filter       = "( login_id = :login_id or email_address = :login_id ) and active = 1"
			, filterParams = { login_id = "dummy" }
			, useCache     = false
			, selectFields = [ "id", "login_id", "email_address", "display_name", "password" ]
		).$results( mockRecord );
		mockBCryptService.$( "checkpw" ).$args( plainText="whatever", hashed=mockRecord.password ).$results( true );
		mockSessionService.$( "setVar" );

		super.assert( userManager.login( loginId="dummy", password="whatever" ) );

		var sessionServiceCallLog = mockSessionService.$callLog().setVar;

		super.assertEquals( 1, sessionServiceCallLog.len() );

		super.assertEquals( expectedSetVarCall, sessionServiceCallLog[1] );
	}

// private helpers
	private any function _getUserManager() output=false {
		mockSessionService = getMockbox().createEmptyMock( "preside.system.services.cfmlScopes.SessionService" );
		mockUserDao        = getMockbox().createStub();
		mockBCryptService  = getMockBox().createEmptyMock( "preside.system.services.encryption.bcrypt.BCryptService" );

		return getMockBox().createMock( object= new preside.system.services.websiteUserManager.WebsiteUserManager(
			  sessionService = mockSessionService
			, userDao        = mockUserDao
			, bcryptService  = mockBCryptService
		) );
	}

}