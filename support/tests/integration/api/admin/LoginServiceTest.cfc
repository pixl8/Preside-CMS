<cfcomponent output="false" extends="tests.resources.HelperObjects.PresideTestCase">

	<cffunction name="beforeTests" access="public" returntype="any" output="false">
		<cfscript>
			_clearRecentPresideServiceFetch();
			_emptyDatabase();
			_dbSync();
			_setupTestData();

			sessionStorage  = new tests.resources.HelperObjects.TestSessionStorage();
			mockEmailService = getMockBox().createEmptyMock( "preside.system.services.email.EmailService" );
			mockGoogleAuthenticator = getMockBox().createEmptyMock( "preside.system.services.authentication.GoogleAuthenticator" );
			mockQrCodeGenerator = getMockBox().createEmptyMock( "preside.system.services.qrcodes.QrCodeGenerator" );
			loginService = new preside.system.services.admin.loginService(
				  logger              = _getTestLogger()
				, userDao             = _getPresideObjectService( forceNewInstance=true ).getObject( "security_user" )
				, sessionStorage      = sessionStorage
				, bCryptService       = _getBCrypt()
				, systemUserList      = "sysadmin"
				, emailService        = mockEmailService
				, googleAuthenticator = mockGoogleAuthenticator
				, qrCodeGenerator     = mockQrCodeGenerator
			);
		</cfscript>
	</cffunction>

	<cffunction name="afterTests" access="public" returntype="any" output="false">
		<cfscript>
			_wipeTestData();
		</cfscript>
	</cffunction>

	<cffunction name="setup" access="public" returntype="any" output="false">
		<cfscript>
			sessionStorage.clearAll();
			request.delete( "__presideCmsAminUserDetails" );
		</cfscript>
	</cffunction>

	<cffunction name="teardown" access="public" returntype="any" output="false">
		<cfscript>
			sessionStorage.clearAll();
			request.delete( "__presideCmsAminUserDetails" );
		</cfscript>
	</cffunction>

<!--- tests --->
	<cffunction name="test01_login_shouldReturnFalse_ifLoginIdNotFound" returntype="void">
		<cfscript>
			super.assertFalse( loginService.login( loginId="a_bad_login_id", password=testUsers[1].pw ), "Login succeeded when the loginId should not have existed in the user store" );
		</cfscript>
	</cffunction>

	<cffunction name="test02_login_shouldReturnFalse_ifLoginIdFound_butPasswordIsIncorrect" returntype="void">
		<cfscript>
			super.assertFalse( loginService.login( loginId=testUsers[1].loginId, password=testUsers[2].pw ), "Login succeeded when the password check should have failed" );
		</cfscript>
	</cffunction>

	<cffunction name="test03_login_shouldReturnTrue_whenLoginIdAndPasswordAreCorrect" returntype="void">
		<cfscript>
			super.assert( loginService.login( loginId=testUsers[2].loginId, password=testUsers[2].pw ), "Login failed when credentials were correct" );
		</cfscript>
	</cffunction>

	<cffunction name="test04_isLoggedIn_shouldReturnFalse_whenNoOnLoggedIn" returntype="void">
		<cfscript>
			super.assertFalse( loginService.isLoggedIn(), "Is logged in returned true, when no sessions should exist." );
		</cfscript>
	</cffunction>

	<cffunction name="test05_isLoggedIn_shouldReturnTrue_whenLoggedInSessionExists" returntype="void">
		<cfscript>
			loginService.login( loginId=testUsers[4].loginId, password=testUsers[4].pw );

			super.assert( loginService.isLoggedIn(), "Is logged in returned false, even though a user session existed." );
		</cfscript>
	</cffunction>

	<cffunction name="test06_getLoggedInUserDetails_shouldReturnStoredDetailsOfLoggedInUser" returntype="void">
		<cfscript>
			var expected = { login_id=testUsers[2].loginId, email_address=testUsers[2].email, id=testUsers[2].id, known_as=testUsers[2].name };
			var result = "";

			loginService.login( loginId=testUsers[2].loginId, password=testUsers[2].pw );

			result = loginService.getLoggedInUserDetails();

			for( var key in expected ) {
				super.assertEquals( expected[ key ], result[ key ] );
			}
		</cfscript>
	</cffunction>

	<cffunction name="test07_getLoggedInUserDetails_shouldReturnEmptyStruct_whenUserIsNotLoggedIn" returntype="void">
		<cfscript>
			var result = "";

			result = loginService.getLoggedInUserDetails();

			super.assertEquals( {}, result );
		</cfscript>
	</cffunction>

	<cffunction name="test08_login_shouldOverrideCurrentlyLoggedInUser_whenUserIsAlreadyLoggedIn" returntype="void">
		<cfscript>
			var expected = testUsers[5].loginId;
			var result = "";

			loginService.login( loginId=testUsers[3].loginId, password=testUsers[3].pw );
			super.assertEquals( testUsers[3].loginId, loginService.getLoggedInUserDetails().login_id, "Test failed, initial user login did not register." );

			loginService.login( loginId=testUsers[5].loginId, password=testUsers[5].pw );
			result = loginService.getLoggedInUserDetails();

			super.assertEquals( expected, result.login_id );
		</cfscript>
	</cffunction>

	<cffunction name="test16_isSystemUser_shouldReturnFalse_whenLoggedInUserIsNotSystemUser" returntype="void">
		<cfscript>
			loginService.login( loginId=testUsers[2].loginId, password=testUsers[2].pw );

			super.assertFalse( loginService.isSystemUser(), "IsSystemUser() returned true for a non-system user" );
		</cfscript>
	</cffunction>

	<cffunction name="test17_isSystemUser_shouldReturnTrue_whenLoggedInUserIsSystemUser" returntype="void">
		<cfscript>
			loginService.login( loginId=testUsers[6].loginId, password=testUsers[6].pw );

			super.assert( loginService.isSystemUser(), "IsSystemUser() returned false for a system user" );
		</cfscript>
	</cffunction>

	<cffunction name="test18_isSystemUser_shouldReturnFalse_whenNoUserLoggedIn" returntype="void">
		<cfscript>
			super.assertFalse( loginService.isSystemUser(), "IsSystemUser() returned true when no one was logged in!" );
		</cfscript>
	</cffunction>

	<cffunction name="test19_logout_shouldLogYouOut" returntype="void">
		<cfscript>
			loginService.login( loginId=testUsers[6].loginId, password=testUsers[6].pw );
			super.assert( loginService.isLoggedIn(), "Test failed, couldn't log in!" );

			loginService.logout();
			super.assertFalse( loginService.isLoggedIn(), "User was not logged out" );
		</cfscript>
	</cffunction>

	<cffunction name="test20_login_shouldAllowLoginWithEmailAddress" returntype="void">
		<cfscript>
			loginService.login( loginId=testUsers[1].email, password=testUsers[1].pw );

			super.assert( loginService.isLoggedIn(), "Login with email failed" );
		</cfscript>
	</cffunction>

	<cffunction name="test21_getLoggedInUserId_shouldReturnTheIdOfTheLoggedInUser" returntype="void">
		<cfscript>
			loginService.login( loginId=testUsers[3].email, password=testUsers[3].pw );

			super.assertEquals( testUsers[3].id, loginService.getLoggedInUserId()  );
		</cfscript>
	</cffunction>

	<cffunction name="test22_getSystemUserId_shouldReturnIdOfFirstUserInConfiguredSystemUserList" returntype="void">
		<cfscript>
			super.assertEquals( testUsers[6].id, loginService.getSystemUserId() );
		</cfscript>
	</cffunction>

	<cffunction name="test23_getSystemUserId_shouldCreateSystemUserIfNoneExists" returntype="void">
		<cfscript>
			var usrId        = "";
			var usrDetails   = {};
			var loginSuccess = "";

			_wipeTestData();

			usrId = loginService.getSystemUserId();

			_wipeTestData();
			_setupTestData();

			assert( Len( Trim( usrId ) ) );
		</cfscript>
	</cffunction>

<!--- private --->
	<cffunction name="_wipeTestData" access="private" returntype="void" output="false">
		<cfscript>
			_deleteData( objectName="security_user", forceDeleteAll=true );
		</cfscript>
	</cffunction>

	<cffunction name="_setupTestData" access="private" returntype="void" output="false">
		<cfscript>
			variables.testUsers = [
				  { loginId="fred"    , pw="some%$p45%word" , name="Big Daddy"   , email="test1@test.com", id="" }
				, { loginId="james"   , pw="aN0THERP4$$word", name="007"         , email="test2@test.com", id="" }
				, { loginId="boris"   , pw="j0ns0n"         , name="Bendy Boris" , email="test3@test.com", id="" }
				, { loginId="pixl8"   , pw="1nter4ct!ve"    , name="Pixl8"       , email="test4@test.com", id="" }
				, { loginId="mandy"   , pw="sdfjlsdf84£rjs" , name="Patinkin"    , email="test5@test.com", id="" }
				, { loginId="sysadmin", pw="ajdlfjasfas&&^" , name="System Admin", email="test6@test.com", id="" }
			];
			for( var user in testUsers ){
				user.id = _insertData( objectName="security_user", data={ known_as=user.name, login_id=user.loginId, password=_bCryptPassword( user.pw ), email_address=user.email } );
			}
		</cfscript>
	</cffunction>
</cfcomponent>