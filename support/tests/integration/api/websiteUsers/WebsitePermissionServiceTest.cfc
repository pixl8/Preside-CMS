component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// tests
	function test01_listPermissionKeys_shouldReturnAllConfiguredPermissionKeys() output=false {
		var userService = _getPermService();
		var expected    = [ "assets.access", "pages.access" ];
		var actual      = userService.listPermissionKeys();

		super.assertEquals( expected, actual.sort( "textnocase" ) );
	}

	function test02_listPermissionKeys_shouldReturnEmptyArray_whenPassedBenefitHasNoAssociatedPermissions() output=false {
		var userService = _getPermService();
		var testBenefit = "somebenefit";

		mockAppliedPermDao.$( "selectData" ).$args(
			  selectFields = [ "granted", "permission_key" ]
			, filter       = { "benefit.id" = testBenefit }
			, forceJoins   = "inner"
		).$results( QueryNew( 'granted,permission_key' ) );

		super.assertEquals( [], userService.listPermissionKeys( benefit=testBenefit ) );
	}

	function test03_listPermissionKeys_shouldReturnListOfGrantedPermissionsAssociatedWithPassedInBenefit() output=false {
		var userService = _getPermService();
		var testBenefit = "somebenefit";
		var testRecords = QueryNew( 'granted,permission_key', 'bit,varchar', [[1,"some.key"],[0,"denied.key"],[0,"another.key"],[1,"another.key"],[1,"test.key"],[0, "test.key"]] );
		var expected    = [ "some.key", "another.key" ];
		var actual      = "";

		mockAppliedPermDao.$( "selectData" ).$args(
			  selectFields = [ "granted", "permission_key" ]
			, filter       = { "benefit.id" = testBenefit }
			, forceJoins   = "inner"
		).$results( testRecords );

		actual = userService.listPermissionKeys( benefit=testBenefit );

		super.assertEquals( expected, actual );
	}

// private helpers
	private any function _getPermService( permissionsConfig=_getDefaultPermsConfig() ) output=false {
		mockWebsiteUserService = getMockbox().createEmptyMock( "preside.system.services.websiteUsers.WebsiteUserService" );
		mockBenefitsDao        = getMockbox().createStub();
		mockUserDao            = getMockbox().createStub();
		mockAppliedPermDao     = getMockbox().createStub();
		mockCacheProvider      = getMockbox().createStub();

		return getMockBox().createMock( object= new preside.system.services.websiteUsers.WebsitePermissionService(
			  websiteUserService = mockWebsiteUserService
			, cacheProvider      = mockCacheProvider
			, permissionsConfig  = arguments.permissionsConfig
			, benefitsDao        = mockBenefitsDao
			, userDao            = mockUserDao
			, appliedPermDao     = mockAppliedPermDao
		) );
	}

	private struct function _getDefaultPermsConfig() output=false {
		return {
			  pages  = [ "access" ]
			, assets = [ "access" ]
		};
	}

}