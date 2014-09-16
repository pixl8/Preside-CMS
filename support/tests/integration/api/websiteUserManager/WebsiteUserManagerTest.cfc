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

// private helpers
	private any function _getUserManager() output=false {
		mockSessionService = getMockbox().createEmptyMock( "preside.system.services.cfmlScopes.SessionService" );

		return new preside.system.services.websiteUserManager.WebsiteUserManager(
			sessionService = mockSessionService
		);
	}

}