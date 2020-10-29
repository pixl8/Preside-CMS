component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// tests
	function test01_listPermissionKeys_shouldReturnAllConfiguredPermissionKeys() output=false {
		var userService = _getPermService();
		var expected    = [ "assets.access", "pages.access" ];
		var actual      = userService.listPermissionKeys();

		super.assertEquals( expected, actual.sort( "textnocase" ) );
	}

	function test02_listPermissionKeys_shouldReturnEmptyArray_whenPassedBenefitHasNoAssociatedPermissions() output=false {
		var permsService = _getPermService();
		var testBenefit  = "somebenefit";

		mockAppliedPermDao.$( "selectData" ).$args(
			  selectFields = [ "granted", "permission_key" ]
			, filter       = "benefit = :website_benefit.id and context is null and context_key is null"
			, filterParams = { "website_benefit.id" = testBenefit }
			, forceJoins   = "inner"
		).$results( QueryNew( 'granted,permission_key' ) );

		super.assertEquals( [], permsService.listPermissionKeys( benefit=testBenefit ) );
	}

	function test03_listPermissionKeys_shouldReturnListOfGrantedPermissionsAssociatedWithPassedInBenefit() output=false {
		var permsService = _getPermService();
		var testBenefit  = "somebenefit";
		var testRecords  = QueryNew( 'granted,permission_key', 'bit,varchar', [[1,"some.key"],[0,"denied.key"],[0,"another.key"],[1,"another.key"],[1,"test.key"],[0, "test.key"]] );
		var expected     = [ "some.key", "another.key" ];
		var actual       = "";

		mockAppliedPermDao.$( "selectData" ).$args(
			  selectFields = [ "granted", "permission_key" ]
			, filter       = "benefit = :website_benefit.id and context is null and context_key is null"
			, filterParams = { "website_benefit.id" = testBenefit }
			, forceJoins   = "inner"
		).$results( testRecords );

		actual = permsService.listPermissionKeys( benefit=testBenefit );

		super.assertEquals( expected, actual );
	}

	function test04_listPermissionKeys_shouldReturnAListOfPermissionsThatHaveBeenFilteredByThePassedFilter() output=false {
		var permsService = _getPermService( permissionsConfig={
			  cms          = [ "login" ]
			, sitetree     = [ "navigate", "read", "add", "edit", "delete" ]
			, assetmanager = {
				  folders = [ "navigate", "read", "add", "edit", "delete" ]
				, assets  = [ "navigate", "read", "add", "edit", "delete" ]
				, blah    = {
					  test = [ "meh", "doh", "blah" ]
					, test2 = [ "tehee" ]
				}
			 }
			, groupmanager = [ "navigate", "read", "add", "edit", "delete" ]
		} );

		var actual       = permsService.listPermissionKeys( filter=[ "assetmanager.folders.*", "!*.delete", "*.edit" ] );
		var expected     = [
			  "sitetree.edit"
			, "assetmanager.folders.navigate"
			, "assetmanager.folders.read"
			, "assetmanager.folders.add"
			, "assetmanager.folders.edit"
			, "assetmanager.assets.edit"
			, "groupmanager.edit"
		];

		super.assertEquals( expected.sort( "textnocase" ), actual.sort( "textnocase" ) );
	}

	function test05_listPermissionKeys_shouldReturnListOfPermissionKeysDerivedFormPassedInUsersBenefitPermsAndPersonalPerms() output=false {
		var permsService       = _getPermService();
		var testUserId         = "test-user-id";
		var testBenefits       = [ "benefita", "benefitb", "benefitc", "benefitd" ];
		var testBenefitRecords = QueryNew( 'granted,permission_key', 'bit,varchar', [[1,"some.key"],[0,"denied.key"],[0,"another.key"],[1,"another.key"],[1,"test.key"],[0, "test.key"]] );
		var testUserRecords    = QueryNew( 'granted,permission_key', 'bit,varchar', [[0, "some.key"], [1, "test.key"]] );
		var expected           = [ "another.key", "test.key" ];
		var actual             = "";

		permsService.$( "listUserBenefits" ).$args( testUserId ).$results( testBenefits );
		mockAppliedPermDao.$( "selectData" ).$args(
			  selectFields = [ "granted", "permission_key" ]
			, filter       = "benefit in ( :website_benefit.id ) and context is null and context_key is null"
			, filterParams = { "website_benefit.id" = testBenefits }
			, forceJoins   = "inner"
			, orderby      = "benefit.priority"
		).$results( testBenefitRecords );

		mockAppliedPermDao.$( "selectData" ).$args(
			  selectFields = [ "granted", "permission_key" ]
			, filter       = "user in ( :website_user.id ) and context is null and context_key is null"
			, filterParams = { "website_user.id" = testUserId }
			, forceJoins   = "inner"
		).$results( testUserRecords );

		actual = permsService.listPermissionKeys( user=testUserId );

		super.assertEquals( expected, actual );
	}

	function test06_hasPermission_shouldReturnFalse_whenLoggedInUserDoesNotHaveAGrantToPassedPermissionKey() output=false {
		var permsService = _getPermService();
		var testUserId   = "fred";

		permsService.$( "listPermissionKeys" ).$args( user=testUserId ).$results( [ "key.a", "key.b", "key.c" ] );
		mockWebsiteLoginService.$( "getLoggedInUserId", testUserId );

		super.assertFalse( permsService.hasPermission( "key.d" ) );
	}

	function test07_hasPermission_shouldReturnTrue_whenLoggedInUserHasAGrantToPassedPermissionKey() output=false {
		var permsService = _getPermService();
		var testUserId   = "fred";

		permsService.$( "listPermissionKeys" ).$args( user=testUserId ).$results( [ "key.a", "key.b", "key.c" ] );
		mockWebsiteLoginService.$( "getLoggedInUserId", testUserId );

		super.assert( permsService.hasPermission( "key.C" ) );
	}

	function test06_hasPermission_shouldReturnFalse_whenLoggedInUserDoesNotHaveAGrantToPassedPermissionKey_andDoesNotHaveAnyContextPerms() output=false {
		var permsService      = _getPermService();
		var testUserId        = "fred";
		var testPermissionKey = "key.d";
		var testContext       = "somecontext";
		var testContextKeys   = [ "keya", "keyb", "keyc" ];


		permsService.$( "listPermissionKeys" ).$args( user=testUserId ).$results( [ "key.a", "key.b", "key.c" ] );
		permsService.$( "listUserBenefits" ).$args( testUserId ).$results( [ "benefita", "benefitb", "benefitc" ] );
		mockWebsiteLoginService.$( "getLoggedInUserId", testUserId );
		mockCacheProvider.$( "get", { perma = true, permb = false, permc = true, permd = true } );

		super.assertFalse( permsService.hasPermission(
			  permissionKey = testPermissionKey
			, context       = testContext
			, contextKeys   = testContextKeys
		) );
	}

	function test07_hasPermission_shouldReturnTrue_whenLoggedInUserHasAGrantToPassedPermissionKey_andDoesNotHaveAnyContextPerms() output=false {
		var permsService      = _getPermService();
		var testUserId        = "fred";
		var testPermissionKey = "key.c";
		var testContext       = "somecontext";
		var testContextKeys   = [ "keya", "keyb", "keyc" ];


		permsService.$( "listPermissionKeys" ).$args( user=testUserId ).$results( [ "key.a", "key.b", "key.c" ] );
		permsService.$( "listUserBenefits" ).$args( testUserId ).$results( [ "benefita", "benefitb", "benefitc" ] );
		mockWebsiteLoginService.$( "getLoggedInUserId", testUserId );
		mockCacheProvider.$( "get", { perma = true, permb = false, permc = true, permd = true } );

		super.assert( permsService.hasPermission(
			  permissionKey = testPermissionKey
			, context       = testContext
			, contextKeys   = testContextKeys
		) );
	}

	function test08_hasPermission_shouldReturnFalse_whenLoggedInUserHasExplicitDenyPermissionForGivenKeys() output=false {
		var permsService      = _getPermService();
		var testUserId        = "fred";
		var testPermissionKey = "key.c";
		var testContext       = "somecontext";
		var testContextKeys   = [ "keya", "keyb", "keyc" ];


		permsService.$( "listPermissionKeys" ).$args( user=testUserId ).$results( [ "key.a", "key.b", "key.c" ] );
		permsService.$( "listUserBenefits" ).$args( testUserId ).$results( [ "benefita", "benefitb", "benefitc" ] );
		mockWebsiteLoginService.$( "getLoggedInUserId", testUserId );
		mockCacheProvider.$( "get", { perma = true, permb = false, "keyb_key.c_fred" = false, permc = true, permd = true } );

		super.assertFalse( permsService.hasPermission(
			  permissionKey = testPermissionKey
			, context       = testContext
			, contextKeys   = testContextKeys
		) );
	}

	function test09_hasPermission_shouldReturnTrue_whenLoggedInUserHasExplicitAccessPermissionForGivenKeys() output=false {
		var permsService      = _getPermService();
		var testUserId        = "fred";
		var testPermissionKey = "key.d";
		var testContext       = "somecontext";
		var testContextKeys   = [ "keya", "keyb", "keyc" ];


		permsService.$( "listPermissionKeys" ).$args( user=testUserId ).$results( [ "key.a", "key.b", "key.c" ] );
		permsService.$( "listUserBenefits" ).$args( testUserId ).$results( [ "benefita", "benefitb", "benefitc" ] );
		mockWebsiteLoginService.$( "getLoggedInUserId", testUserId );
		mockCacheProvider.$( "get", { perma = true, permb = false, permc = true, "keyb_key.d_fred" = true, permd = true } );

		super.assert( permsService.hasPermission(
			  permissionKey = testPermissionKey
			, context       = testContext
			, contextKeys   = testContextKeys
		) );
	}

	function test10_hasPermission_shouldReturnFalse_whenLoggedInUserHasBenefitInheritedDenyPermissionForGivenKeys() output=false {
		var permsService      = _getPermService();
		var testUserId        = "fred";
		var testPermissionKey = "key.c";
		var testContext       = "somecontext";
		var testContextKeys   = [ "keya", "keyb", "keyc" ];


		permsService.$( "listPermissionKeys" ).$args( user=testUserId ).$results( [ "key.a", "key.b", "key.c" ] );
		permsService.$( "listUserBenefits" ).$args( testUserId ).$results( [ "benefita", "benefitb", "benefitc" ] );
		mockWebsiteLoginService.$( "getLoggedInUserId", testUserId );
		mockCacheProvider.$( "get", { perma = true, permb = false, "keyb_key.c_benefita" = false, "keyb_key.c_benefitb" = true, "keyb_key.c_benefitc" = true, permc = true, permd = true } );

		super.assertFalse( permsService.hasPermission(
			  permissionKey = testPermissionKey
			, context       = testContext
			, contextKeys   = testContextKeys
		) );
	}

	function test11_hasPermission_shouldReturnTrue_whenLoggedInUserHasExplicitAccessPermissionForGivenKeys() output=false {
		var permsService      = _getPermService();
		var testUserId        = "fred";
		var testPermissionKey = "key.d";
		var testContext       = "somecontext";
		var testContextKeys   = [ "keya", "keyb", "keyc" ];


		permsService.$( "listPermissionKeys" ).$args( user=testUserId ).$results( [ "key.a", "key.b", "key.c" ] );
		permsService.$( "listUserBenefits" ).$args( testUserId ).$results( [ "benefita", "benefitb", "benefitc" ] );
		mockWebsiteLoginService.$( "getLoggedInUserId", testUserId );
		mockCacheProvider.$( "get", { perma = true, permb = false, permc = true, "keyb_key.d_benefita" = true, "keyb_key.d_benefitb" = false, "keyb_key.d_benefitc" = false, permd = true } );

		super.assert( permsService.hasPermission(
			  permissionKey = testPermissionKey
			, context       = testContext
			, contextKeys   = testContextKeys
		) );
	}



// private helpers
	private any function _getPermService( permissionsConfig=_getDefaultPermsConfig() ) output=false {
		mockWebsiteLoginService = getMockbox().createEmptyMock( "preside.system.services.websiteUsers.WebsiteLoginService" );
		mockBenefitsDao        = getMockbox().createStub();
		mockUserDao            = getMockbox().createStub();
		mockAppliedPermDao     = getMockbox().createStub();
		mockCacheProvider      = getMockbox().createStub();

		var service = getMockBox().createMock( object= new preside.system.services.websiteUsers.WebsitePermissionService(
			  websiteLoginService = mockWebsiteLoginService
			, cacheProvider      = mockCacheProvider
			, permissionsConfig  = arguments.permissionsConfig
			, benefitsDao        = mockBenefitsDao
			, userDao            = mockUserDao
			, appliedPermDao     = mockAppliedPermDao
		) );

		service.$( "$isFeatureEnabled" ).$args( "websitebenefits" ).$results( true );

		return service;
	}

	private struct function _getDefaultPermsConfig() output=false {
		return {
			  pages  = [ "access" ]
			, assets = [ "access" ]
		};
	}

}