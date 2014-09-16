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

// private helpers
	private any function _getUserManager() output=false {
		mockSessionService = getMockbox().createEmptyMock( "preside.system.services.cfmlScopes.SessionService" );

		return new preside.system.services.websiteUserManager.WebsiteUserManager(
			sessionService = mockSessionService
		);
	}

}