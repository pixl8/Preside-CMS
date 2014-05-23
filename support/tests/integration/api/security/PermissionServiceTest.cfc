component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// SETUP, etc
	function setup() {
		super.setup();

		testPerms = {
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
		};

		testRoles = {
			  administrator = [ "*" ]
			, tester        = [ "*.delete", "assetmanager.*.read", "sitetree.*", "!groupmanager.delete", "groupmanager.edit", "!*.add" ]
			, user          = [ "cms.login", "assetmanager.blah.test" ]
		}
	}

// TESTS
	function test01_listRoles_shouldReturnEmptyArray_whenNoRolesRegistered(){
		super.assertEquals( [], _getPermissionService().listRoles() );
	}

	function test02_listRoles_shouldReturnArrayOfConfiguredRoles(){
		var expected = [ "administrator", "tester", "user" ];
		var actual   = _getPermissionService( roles=testRoles ).listRoles();

		actual.sort( "textnocase" );

		super.assertEquals( expected, actual );
	}

	function test03_listPermissionKeys_shouldReturnEmptyArrayWhenNoPermissionsSet(){
		var expected = [ ];
		var actual   = _getPermissionService( roles=testRoles ).listPermissionKeys();

		super.assertEquals( expected, actual );
	}

	function test04_listPermissionKeys_shouldReturnArrayOfFlattendPermissionKeys(){
		var expected = [
			  "cms.login"
			, "sitetree.navigate"
			, "sitetree.read"
			, "sitetree.add"
			, "sitetree.edit"
			, "sitetree.delete"
			, "assetmanager.folders.navigate"
			, "assetmanager.folders.read"
			, "assetmanager.folders.add"
			, "assetmanager.folders.edit"
			, "assetmanager.folders.delete"
			, "assetmanager.assets.navigate"
			, "assetmanager.assets.read"
			, "assetmanager.assets.add"
			, "assetmanager.assets.edit"
			, "assetmanager.assets.delete"
			, "assetmanager.blah.test.meh"
			, "assetmanager.blah.test.doh"
			, "assetmanager.blah.test.blah"
			, "assetmanager.blah.test2.tehee"
			, "groupmanager.navigate"
			, "groupmanager.read"
			, "groupmanager.add"
			, "groupmanager.edit"
			, "groupmanager.delete"
		];
		var actual = _getPermissionService( permissions=testPerms ).listPermissionKeys();

		expected.sort( "textnocase" );
		actual.sort( "textnocase" );

		super.assertEquals( expected, actual );
	}

	function test05_listPermissionKeys_shouldReturnPermissionsThatHaveBeenExplicitlyConfiguredOnPassedRole(){
		var expected = [ "assetmanager.blah.test", "cms.login" ];
		var actual   = _getPermissionService( permissions=testPerms, roles=testRoles ).listPermissionKeys( role="user" );

		super.assertEquals( expected, actual.sort( "textnocase" ) );
	}

	function test06_listPermissionKeys_shouldReturnExpandedPermissions_whereSuppliedRoleHasPermissionsConfiguredWithWildCardsAndExclusions(){
		var expected = [
			  "sitetree.navigate"
			, "sitetree.read"
			, "sitetree.edit"
			, "sitetree.delete"
			, "assetmanager.folders.read"
			, "assetmanager.assets.read"
			, "assetmanager.folders.delete"
			, "assetmanager.assets.delete"
			, "groupmanager.edit"
		];

		var actual   = _getPermissionService( permissions=testPerms, roles=testRoles ).listPermissionKeys( role="tester" );

		super.assertEquals( expected.sort( "textnocase" ), actual.sort( "textnocase" ) );
	}

// PRIVATE HELPERS
	private any function _getPermissionService( struct roles={}, struct permissions={} ) output=false {
		return new preside.system.api.security.PermissionService(
			  presideObjectService = _getPresideObjectService()
			, logger               = _getTestLogger()
			, rolesConfig          = arguments.roles
			, permissionsConfig    = arguments.permissions
		);
	}
}