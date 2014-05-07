<cfcomponent output="false" extends="tests.resources.HelperObjects.PresideTestCase">

	<cffunction name="beforeTests" access="public" returntype="any" output="false">
		<cfscript>
			_emptyDatabase();
			_dbSync();
			_setupTestData();

			sessionService  = new preside.system.api.cfmlScopes.SessionService();
			securityService = new preside.system.api.admin.SecurityService(
				  logger               = _getTestLogger()
				, presideObjectService = _getPresideObjectService()
				, sessionService       = sessionService
				, bCryptService        = _getBCrypt()
				, systemUserList       = "sysadmin"
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
			sessionService.clearAll();
		</cfscript>
	</cffunction>

	<cffunction name="teardown" access="public" returntype="any" output="false">
		<cfscript>
			sessionService.clearAll();
		</cfscript>
	</cffunction>

<!--- tests --->
	<cffunction name="test01_login_shouldReturnFalse_ifLoginIdNotFound" returntype="void">
		<cfscript>
			super.assertFalse( securityService.login( loginId="a_bad_login_id", password=testUsers[1].pw ), "Login succeeded when the loginId should not have existed in the user store" );
		</cfscript>
	</cffunction>

	<cffunction name="test02_login_shouldReturnFalse_ifLoginIdFound_butPasswordIsIncorrect" returntype="void">
		<cfscript>
			super.assertFalse( securityService.login( loginId=testUsers[1].loginId, password=testUsers[2].pw ), "Login succeeded when the password check should have failed" );
		</cfscript>
	</cffunction>

	<cffunction name="test03_login_shouldReturnTrue_whenLoginIdAndPasswordAreCorrect" returntype="void">
		<cfscript>
			super.assert( securityService.login( loginId=testUsers[2].loginId, password=testUsers[2].pw ), "Login failed when credentials were correct" );
		</cfscript>
	</cffunction>

	<cffunction name="test04_isLoggedIn_shouldReturnFalse_whenNoOnLoggedIn" returntype="void">
		<cfscript>
			super.assertFalse( securityService.isLoggedIn(), "Is logged in returned true, when no sessions should exist." );
		</cfscript>
	</cffunction>

	<cffunction name="test05_isLoggedIn_shouldReturnTrue_whenLoggedInSessionExists" returntype="void">
		<cfscript>
			securityService.login( loginId=testUsers[4].loginId, password=testUsers[4].pw );

			super.assert( securityService.isLoggedIn(), "Is logged in returned false, even though a user session existed." );
		</cfscript>
	</cffunction>

	<cffunction name="test06_getLoggedInUserDetails_shouldReturnStoredDetailsOfLoggedInUser" returntype="void">
		<cfscript>
			var expected = { loginId=testUsers[2].loginId, emailAddress=testUsers[2].email, userId=testUsers[2].id, knownAs=testUsers[2].name };
			var result = "";

			securityService.login( loginId=testUsers[2].loginId, password=testUsers[2].pw );

			result = securityService.getLoggedInUserDetails();

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test07_getLoggedInUserDetails_shouldReturnEmptyStruct_whenUserIsNotLoggedIn" returntype="void">
		<cfscript>
			var result = "";

			result = securityService.getLoggedInUserDetails();

			super.assertEquals( {}, result );
		</cfscript>
	</cffunction>

	<cffunction name="test08_login_shouldOverrideCurrentlyLoggedInUser_whenUserIsAlreadyLoggedIn" returntype="void">
		<cfscript>
			var expected = { loginId=testUsers[5].loginId, emailAddress=testUsers[5].email, userId=testUsers[5].id, knownAs=testUsers[5].name };
			var result = "";

			securityService.login( loginId=testUsers[3].loginId, password=testUsers[3].pw );
			super.assertEquals( testUsers[3].loginId, securityService.getLoggedInUserDetails().loginId, "Test failed, initial user login did not register." );

			securityService.login( loginId=testUsers[5].loginId, password=testUsers[5].pw );
			result = securityService.getLoggedInUserDetails();

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test09_hasPermission_shouldReturnTrue_whenLoggedInUserHasOneOrMoreRolesWithPassedPermission" returntype="void">
		<cfscript>
			securityService.login( loginId=testUsers[4].loginId, password=testUsers[4].pw );

			super.assert( securityService.hasPermission( permission="components" ) );
		</cfscript>
	</cffunction>

	<cffunction name="test10_hasPermission_shouldReturnFalse_whenLoggedInUserDoesNotHaveAnyRolesWithPermission" returntype="void">
		<cfscript>
			securityService.login( loginId=testUsers[5].loginId, password=testUsers[5].pw );

			super.assertFalse( securityService.hasPermission( permission="audit_log" ) );
		</cfscript>
	</cffunction>


	<cffunction name="test14_hasPermission_shouldReturnTrueForAnything_whenUserIsSystemUser" returntype="void">
		<cfscript>
			securityService.login( loginId=testUsers[6].loginId, password=testUsers[6].pw );

			super.assert( securityService.hasPermission( permission="madeuppermission" ), "System user logged and should always have permission. Method returned false, however." );
		</cfscript>
	</cffunction>

	<cffunction name="test15_hasPermission_shouldReturnFalse_whenUserNotLoggedIn" returntype="void">
		<cfscript>
			super.assertFalse( securityService.hasPermission( permission="components" ), "Somehow, a non logged in user has permission!" );
		</cfscript>
	</cffunction>

	<cffunction name="test16_isSystemUser_shouldReturnFalse_whenLoggedInUserIsNotSystemUser" returntype="void">
		<cfscript>
			securityService.login( loginId=testUsers[2].loginId, password=testUsers[2].pw );

			super.assertFalse( securityService.isSystemUser(), "IsSystemUser() returned true for a non-system user" );
		</cfscript>
	</cffunction>

	<cffunction name="test17_isSystemUser_shouldReturnTrue_whenLoggedInUserIsSystemUser" returntype="void">
		<cfscript>
			securityService.login( loginId=testUsers[6].loginId, password=testUsers[6].pw );

			super.assert( securityService.isSystemUser(), "IsSystemUser() returned false for a system user" );
		</cfscript>
	</cffunction>

	<cffunction name="test18_isSystemUser_shouldReturnFalse_whenNoUserLoggedIn" returntype="void">
		<cfscript>
			super.assertFalse( securityService.isSystemUser(), "IsSystemUser() returned true when no one was logged in!" );
		</cfscript>
	</cffunction>

	<cffunction name="test19_logout_shouldLogYouOut" returntype="void">
		<cfscript>
			securityService.login( loginId=testUsers[6].loginId, password=testUsers[6].pw );
			super.assert( securityService.isLoggedIn(), "Test failed, couldn't log in!" );

			securityService.logout();
			super.assertFalse( securityService.isLoggedIn(), "User was not logged out" );
		</cfscript>
	</cffunction>

	<cffunction name="test20_login_shouldAllowLoginWithEmailAddress" returntype="void">
		<cfscript>
			securityService.login( loginId=testUsers[1].email, password=testUsers[1].pw );

			super.assert( securityService.isLoggedIn(), "Login with email failed" );
		</cfscript>
	</cffunction>

	<cffunction name="test21_getLoggedInUserId_shouldReturnTheIdOfTheLoggedInUser" returntype="void">
		<cfscript>
			securityService.login( loginId=testUsers[3].email, password=testUsers[3].pw );

			super.assertEquals( testUsers[3].id, securityService.getLoggedInUserId()  );
		</cfscript>
	</cffunction>

	<cffunction name="test22_getSystemUserId_shouldReturnIdOfFirstUserInConfiguredSystemUserList" returntype="void">
		<cfscript>
			super.assertEquals( testUsers[6].id, securityService.getSystemUserId() );
		</cfscript>
	</cffunction>

	<cffunction name="test23_getSystemUserId_shouldCreateSystemUserIfNoneExists" returntype="void">
		<cfscript>
			var usrId        = "";
			var usrDetails   = {};
			var loginSuccess = "";

			_wipeTestData();

			usrId = securityService.getSystemUserId();
			assert( Len( Trim( usrId ) ) );

			loginSuccess = securityService.login( loginId="sysadmin", password="password" );
			usrDetails   = securityService.getLoggedInUserDetails();

			_wipeTestData();
			_setupTestData();

			super.assert( loginSuccess );
			super.assertEquals( "System Administrator", usrDetails.knownAs );
			super.assertEquals( "", usrDetails.emailAddress );
		</cfscript>
	</cffunction>

<!--- private --->
	<cffunction name="_wipeTestData" access="private" returntype="void" output="false">
		<cfscript>
			_deleteData( objectName="security_user"               , forceDeleteAll=true );
			_deleteData( objectName="security_role_permission"    , forceDeleteAll=true );
			_deleteData( objectName="security_role"               , forceDeleteAll=true );
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
				user.id = _insertData( objectName="security_user", data={ label=user.name, login_id=user.loginId, password=_bCryptPassword( user.pw ), email_address=user.email } );
			}

			variables.testRoles = [
				  { key="administrator", name="Administrator" , id="" }
				, { key="editor"       , name="Content Editor", id="" }
				, { key="testrole"     , name="Test role"     , id="" }
			];
			for( var role in testRoles ){
				role.id = _insertData( objectName="security_role", data={ label=role.name , key=role.key } );
			}

			// user role joins
			_insertData( objectName="security_role__join__security_user", data={ security_role=testRoles[1].id, security_user=testUsers[1].id } );
			_insertData( objectName="security_role__join__security_user", data={ security_role=testRoles[1].id, security_user=testUsers[2].id } );
			_insertData( objectName="security_role__join__security_user", data={ security_role=testRoles[2].id, security_user=testUsers[3].id } );
			_insertData( objectName="security_role__join__security_user", data={ security_role=testRoles[2].id, security_user=testUsers[4].id } );
			_insertData( objectName="security_role__join__security_user", data={ security_role=testRoles[3].id, security_user=testUsers[5].id } );
			_insertData( objectName="security_role__join__security_user", data={ security_role=testRoles[3].id, security_user=testUsers[4].id } );
			_insertData( objectName="security_role__join__security_user", data={ security_role=testRoles[3].id, security_user=testUsers[3].id } );

			// role permissions
			// targets: *, role: administrator
			_insertData( objectName="security_role_permission", data={ label="admin_user_system", security_role=testRoles[1].id } );
			_insertData( objectName="security_role_permission", data={ label="site_tree"        , security_role=testRoles[1].id } );
			_insertData( objectName="security_role_permission", data={ label="asset_manager"    , security_role=testRoles[1].id } );
			_insertData( objectName="security_role_permission", data={ label="components"       , security_role=testRoles[1].id } );
			_insertData( objectName="security_role_permission", data={ label="audit_log"        , security_role=testRoles[1].id } );

			// targets: components, roles: content editor
			_insertData( objectName="security_role_permission", data={ label="components", security_role=testRoles[2].id } );
			_insertData( objectName="security_role_permission", data={ label="components", security_role=testRoles[3].id } );
		</cfscript>
	</cffunction>
</cfcomponent>