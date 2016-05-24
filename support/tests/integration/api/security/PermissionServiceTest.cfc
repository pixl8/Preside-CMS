component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// SETUP, etc
	function setup() {
		super.setup();

		testPerms = {
			  "cms"          = [ "login" ]
			, "sitetree"     = [ "navigate", "read", "add", "edit", "delete" ]
			, "assetmanager" = {
				  "folders" = [ "navigate", "read", "add", "edit", "delete" ]
				, "assets"  = [ "navigate", "read", "add", "edit", "delete" ]
				, "blah"    = {
					  "test" = [ "meh", "doh", "blah" ]
					, "test2" = [ "tehee" ]
				}
			 }
			, "groupmanager" = [ "navigate", "read", "add", "edit", "delete" ]
		};

		"testRoles" = {
			  "administrator" = [ "*" ]
			, "tester"        = [ "*.delete", "assetmanager.*.read", "sitetree.*", "!groupmanager.delete", "groupmanager.edit", "!*.add" ]
			, "user"          = [ "cms.login", "assetmanager.blah.test.*", "sitetree.navigate" ]
		};
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
		var expected = [
			  "assetmanager.blah.test.blah"
			, "assetmanager.blah.test.doh"
			, "assetmanager.blah.test.meh"
			, "cms.login"
			, "sitetree.navigate"
		];
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

	function test07_listPermissionKeys_shouldReturnEmptyArray_whenPassedGroupDoesNotExist(){
		var actual   = "";
		var permsService = _getPermissionService( permissions=testPerms, roles=testRoles );
		var expected = [];

		mockGroupDao.$( "selectData" )
			.$args( selectFields=["roles"], id="testgroup" )
			.$results( QueryNew('roles' ) );

		actual = permsService.listPermissionKeys( group="testgroup" );

		super.assertEquals( expected.sort( "textnocase" ), actual.sort( "textnocase" ) );
	}

	function test08_listPermissionKeys_shouldReturnPermissionsForGivenGroup_basedOnTheGroupsAssociatedRoles(){
		var actual   = "";
		var permsService = _getPermissionService( permissions=testPerms, roles=testRoles );
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
			, "cms.login"
			, "assetmanager.blah.test.meh"
			, "assetmanager.blah.test.doh"
			, "assetmanager.blah.test.blah"
		];

		mockGroupDao.$( "selectData" )
			.$args( selectFields=["roles"], id="testgroup" )
			.$results( QueryNew('roles', 'varchar', ['tester,user'] ) );

		actual = permsService.listPermissionKeys( group="testgroup" );

		super.assertEquals( expected.sort( "textnocase" ), actual.sort( "textnocase" ) );
	}

	function test09_listPermissionKeys_shouldReturnEmptyArray_whenPassedUserDoesHasNoGroups(){
		var actual   = "";
		var permsService = _getPermissionService( permissions=testPerms, roles=testRoles );
		var expected = [];

		mockUserDao.$( "selectManyToManyData" )
			.$args( selectFields=["groups.id"], propertyName="groups", id="testuser" )
			.$results( QueryNew('id' ) );

		actual = permsService.listPermissionKeys( user="testuser" );

		super.assertEquals( expected.sort( "textnocase" ), actual.sort( "textnocase" ) );
	}

	function test10_listPermissionKeys_shouldReturnPermissionKeysForAllGroupsAssociatedWithPassedUser(){
		var actual   = "";
		var permsService = _getPermissionService( permissions=testPerms, roles=testRoles );
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
			, "cms.login"
			, "assetmanager.blah.test.meh"
			, "assetmanager.blah.test.doh"
			, "assetmanager.blah.test.blah"
		];

		mockUserDao.$( "selectManyToManyData" )
			.$args( selectFields=["groups.id"], propertyName="groups", id="me" )
			.$results( QueryNew('id', 'varchar', [['testgroup'],['testgroup2']] ) );

		mockGroupDao.$( "selectData" )
			.$args( selectFields=["roles"], id="testgroup" )
			.$results( QueryNew('roles', 'varchar', ['tester'] ) );

		mockGroupDao.$( "selectData" )
			.$args( selectFields=["roles"], id="testgroup2" )
			.$results( QueryNew('roles', 'varchar', ['user'] ) );

		actual = permsService.listPermissionKeys( user="me" );

		super.assertEquals( expected.sort( "textnocase" ), actual.sort( "textnocase" ) );
	}

	function test11_hasPermission_shouldReturnTrue_whenLoggedInUserIsSystemUser(){
		var permsService = _getPermissionService( permissions=testPerms, roles=testRoles );

		mockLoginService.$( "getLoggedInUserId", "me" );
		mockLoginService.$( "isSystemUser", true );

		super.assert( permsService.hasPermission( permissionKey="some.key" ), "A system user should always have permission, yet method said no!" );
	}

	function test12_hasPermission_shouldReturnFalse_whenLoggedInUserIsNotSystemUserAndDoesNotHaveAccessToSuppliedPermissionKey(){
		var permsService = _getPermissionService( permissions=testPerms, roles=testRoles );

		mockLoginService.$( "getLoggedInUserId", "me" );
		mockLoginService.$( "isSystemUser", false );

		permsService.$( "listPermissionKeys" ).$args( user="me" ).$results( [ "some.key", "another.key" ] );

		super.assertFalse( permsService.hasPermission( permissionKey="key.i.do.not.have" ), "Shouldn't have permission, yet returned that I do" );
	}

	function test13_hasPermission_shoultReturnTrue_whenLoggedInUserIsNotSystemUserButHasAccessToSuppliedPermissionKey(){
		var permsService = _getPermissionService( permissions=testPerms, roles=testRoles );

		mockLoginService.$( "getLoggedInUserId", "me" );
		mockLoginService.$( "isSystemUser", false );

		permsService.$( "listPermissionKeys" ).$args( user="me" ).$results( [ "some.key", "another.key" ] );

		super.assert( permsService.hasPermission( permissionKey="another.Key" ), "Should have permission, yet returned that I don't :(" );
	}

	function test14_hasPermission_shouldReturnTrue_whenPassedUserIsSystemUser(){
		var permsService = _getPermissionService( permissions=testPerms, roles=testRoles );

		mockLoginService.$( "getLoggedInUserId", "me" );
		mockLoginService.$( "isSystemUser", true );

		super.assert( permsService.hasPermission( permissionKey="some.key", userId="me" ), "A system user should always have permission, yet method said no!" );
	}

	function test15_hasPermission_shouldReturnFalse_whenPassedUserIsNotSystemUserAndDoesNotHaveAccessToSuppliedPermissionKey(){
		var permsService = _getPermissionService( permissions=testPerms, roles=testRoles );

		mockLoginService.$( "getLoggedInUserId", "me" );

		permsService.$( "listPermissionKeys" ).$args( user="someoneelse" ).$results( [ "some.key", "another.key" ] );

		super.assertFalse( permsService.hasPermission( permissionKey="key.i.do.not.have", userId="someoneelse" ), "Shouldn't have permission, yet returned that I do" );
	}

	function test16_hasPermission_shoultReturnTrue_whenPassedUserIsNotSystemUserButHasAccessToSuppliedPermissionKey(){
		var permsService = _getPermissionService( permissions=testPerms, roles=testRoles );

		mockLoginService.$( "getLoggedInUserId", "me" );

		permsService.$( "listPermissionKeys" ).$args( user="anotherUserThatIsNotMe" ).$results( [ "some.key", "another.key" ] );

		super.assert( permsService.hasPermission( permissionKey="another.key", userId="anotherUserThatIsNotMe" ), "Should have permission, yet returned that I don't :(" );
	}

	function test17_hasPermission_shouldReturnTrue_whenPassedInUserDoesNotHaveRolePermissionBUTdoesHaveContextPermissionForGivenContextAndKey(){
		var permsService = _getPermissionService( permissions=testPerms, roles=testRoles );
		var hasPerm      = "";
		var mockContextPerms = QueryNew( "granted,context_key", 'bit,varchar', [[ 1, "somekey" ] ] );

		mockLoginService.$( "getLoggedInUserId", "me" );
		mockLoginService.$( "isSystemUser", false );

		permsService.$( "listPermissionKeys" ).$args( user="me" ).$results( [ "some.key", "another.key" ] );
		permsService.$( "listUserGroups" ).$args( user="me" ).$results( [ "somegroup", "anothergroup" ] );

		mockContextPermDao.$( "selectData" ).$args(
			  selectFields = [ "Max( granted ) as granted", "context_key" ]
			, filter       = { context = "someContext", permission_key = "a.new.key", security_group = [ "somegroup", "anothergroup" ] }
			, groupBy      = "context_key"
			, useCache     = false
		).$results( mockContextPerms );

		hasPerm = permsService.hasPermission( permissionKey="a.new.key", context="someContext", contextKeys=[ "somekey" ] );

		super.assert( hasPerm, "Should have permission, yet returned that I don't :(" );
	}

	function test18_hasPermission_shouldReturnFalse_whenPassedInUserHasRolePermissionBUThasExplictContextPermissionDenialForGivenContextAndKey(){
		var permsService = _getPermissionService( permissions=testPerms, roles=testRoles );
		var hasPerm      = "";
		var mockContextPerms = QueryNew( "granted,context_key", 'bit,varchar', [ [ 0, "somekey" ] ] );

		mockLoginService.$( "getLoggedInUserId", "me" );
		mockLoginService.$( "isSystemUser", false );

		permsService.$( "listPermissionKeys" ).$args( user="me" ).$results( [ "some.key", "a.new.key", "another.key" ] );
		permsService.$( "listUserGroups" ).$args( user="me" ).$results( [ "somegroup", "anothergroup" ] );

		mockContextPermDao.$( "selectData" ).$args(
			  selectFields = [ "Max( granted ) as granted", "context_key" ]
			, filter       = { context = "someContext", permission_key = "a.new.key", security_group = [ "somegroup", "anothergroup" ] }
			, groupBy      = "context_key"
			, useCache     = false
		).$results( mockContextPerms );

		hasPerm = permsService.hasPermission( permissionKey="a.new.key", context="someContext", contextKeys=[ "somekey" ] );

		super.assertFalse( hasPerm, "Should not have permission, yet returned that I do :(" );
	}

	function test19_hasPermission_shouldReturnTrue_whenPassedInUserHasRolePermissionANDhasNoExplictContextPermissionSetForGivenContext(){
		var permsService = _getPermissionService( permissions=testPerms, roles=testRoles );
		var hasPerm      = "";
		var mockContextPerms = QueryNew( "granted,context_key", 'bit,varchar', [] );

		mockLoginService.$( "getLoggedInUserId", "me" );
		mockLoginService.$( "isSystemUser", false );

		permsService.$( "listPermissionKeys" ).$args( user="me" ).$results( [ "some.key", "a.new.key", "another.key", "my.perm.key" ] );
		permsService.$( "listUserGroups" ).$args( user="me" ).$results( [ "somegroup", "anothergroup" ] );

		mockContextPermDao.$( "selectData" ).$args(
			  selectFields = [ "Max( granted ) as granted", "context_key" ]
			, filter       = { context = "someContext", permission_key = "my.perm.key", security_group = [ "somegroup", "anothergroup" ] }
			, groupBy      = "context_key"
			, useCache     = false
		).$results( mockContextPerms );

		hasPerm = permsService.hasPermission( permissionKey="my.perm.key", context="someContext", contextKeys=[ "somekey", "anotherContextKey" ] );

		super.assert( hasPerm, "Should have permission, yet returned that I do not :(" );
	}

	function test20_hasPermission_shouldReturnFirstGrantOrDenial_whenMultipleContextKeysAreSuppliedThatHaveMatches(){
		var permsService = _getPermissionService( permissions=testPerms, roles=testRoles );
		var hasPerm      = "";
		var mockContextPerms = QueryNew( "granted,context_key", 'bit,varchar', [
			    [ 0, "some.context.key3" ]
			  , [ 1, "somekey"           ]
			  , [ 0, "some.context.key"  ]
		] );

		mockLoginService.$( "getLoggedInUserId", "me" );
		mockLoginService.$( "isSystemUser", false );

		permsService.$( "listPermissionKeys" ).$args( user="me" ).$results( [ "some.key", "another.key" ] );
		permsService.$( "listUserGroups" ).$args( user="me" ).$results( [ "somegroup", "anothergroup" ] );

		mockContextPermDao.$( "selectData" ).$args(
			  selectFields = [ "Max( granted ) as granted", "context_key" ]
			, filter       = { context = "someContext", permission_key = "a.new.key", security_group = [ "somegroup", "anothergroup" ] }
			, groupBy      = "context_key"
			, useCache     = false
		).$results( mockContextPerms );

		hasPerm = permsService.hasPermission( permissionKey="a.new.key", context="someContext", contextKeys=[ "somekey", "some.context.key3", "some.context.key" ] );

		super.assert( hasPerm, "Should have permission, yet returned that I do not :(" );
	}

	function test21_listPermissions_shouldReturnFilteredListOfPermissions_whenFilterSupplied() {
		var permsService = _getPermissionService( permissions=testPerms, roles=testRoles );
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

	function test22_getContextPermissions_shouldReturnStructureThatProvidesGroupsWhoHaveBeenGrantedAndDeniedAccesToProvidedPermissionKeysForTheGivenContext(){
		var permsService    = _getPermissionService( permissions=testPerms, roles=testRoles );
		var actual          = "";
		var mockQueryResult = QueryNew( 'permission_key,granted,security_group,group_name', 'varchar,bit,varchar,varchar', [
			  [ "assetmanager.folders.navigate", 1, "groupx", "group x" ]
			, [ "sitetree.edit"                , 1, "groupx", "group x" ]
			, [ "groupmanager.edit"            , 0, "groupy", "group y" ]
			, [ "groupmanager.edit"            , 1, "groupz", "group z" ]
			, [ "groupmanager.edit"            , 0, "groupa", "group a" ]
			, [ "groupmanager.edit"            , 1, "groupb", "group b" ]
		] );
		var expected        = {
			  "sitetree.edit"                 = { granted=[{id="groupx", name="group x"}], denied=[] }
			, "assetmanager.folders.navigate" = { granted=[{id="groupx", name="group x"}], denied=[] }
			, "assetmanager.folders.read"     = { granted=[], denied=[] }
			, "assetmanager.folders.add"      = { granted=[], denied=[] }
			, "assetmanager.folders.edit"     = { granted=[], denied=[] }
			, "assetmanager.assets.edit"      = { granted=[], denied=[] }
			, "groupmanager.edit"             = { granted=[{id="groupz", name="group z"},{id="groupb", name="group b"}], denied=[{id="groupy", name="group y"},{id="groupa", name="group a"}] }
		};
		var expandedPermKeys = [ "sitetree.edit","assetmanager.folders.navigate","assetmanager.folders.read","assetmanager.folders.add","assetmanager.folders.edit","assetmanager.assets.edit","groupmanager.edit" ];

		expandedPermKeys = expandedPermKeys.sort( "textnocase" );

		mockContextPermDao.$( "selectData" ).$args(
			  selectFields = [ "granted", "permission_key", "security_group", "security_group.label as group_name" ]
			, filter       = { context = "someContext", context_key = [ "aContextKey" ], permission_key = expandedPermKeys }
		).$results( mockQueryResult );

		actual = permsService.getContextPermissions(
			  context        = "someContext"
			, contextKeys    = [ "aContextKey" ]
			, permissionKeys = [ "assetmanager.folders.*", "!*.delete", "*.edit" ]
		);


		super.assertEquals( expected, actual );
	}

	function test23_syncContextPermissions_shouldEnsureAccessAndDenyRightsAreAppliedToSuppliedGroupsAndNoOthers_forGivenPermissionAndContext(){
		var permsService    = _getPermissionService( permissions=testPerms, roles=testRoles );
		var testContext     = "thisisatest";
		var testContextKey  = "thisisakeytest";
		var testPerm        = "somePerm";
		var testGrantGroups = [ "group1", "group2" ];
		var testDenyGroups  = [ "group3", "group9", "group10" ];

		mockContextPermDao.$( "deleteData" ).$args(
			filter = { context=testContext, context_key=testContextKey, permission_key=testPerm }
		).$results( 4 );

		mockContextPermDao.$( "insertData" ).$args(
			data = {
				  permission_key = testPerm
				, context        = testContext
				, context_key    = testContextKey
				, security_group = "group1"
				, granted        = 1
			}
		).$results( "" );

		mockContextPermDao.$( "insertData" ).$args(
			data = {
				  permission_key = testPerm
				, context        = testContext
				, context_key    = testContextKey
				, security_group = "group2"
				, granted        = 1
			}
		).$results( "" );

		mockContextPermDao.$( "insertData" ).$args(
			data = {
				  permission_key = testPerm
				, context        = testContext
				, context_key    = testContextKey
				, security_group = "group3"
				, granted        = 0
			}
		).$results( "" );

		mockContextPermDao.$( "insertData" ).$args(
			data = {
				  permission_key = testPerm
				, context        = testContext
				, context_key    = testContextKey
				, security_group = "group9"
				, granted        = 1
			}
		).$results( "" );

		mockContextPermDao.$( "insertData" ).$args(
			data = {
				  permission_key = testPerm
				, context        = testContext
				, context_key    = testContextKey
				, security_group = "group10"
				, granted        = 1
			}
		).$results( "" );

		permsService.syncContextPermissions(
			  context         = testContext
			, contextKey      = testContextKey
			, permissionKey   = testPerm
			, grantedToGroups = testGrantGroups
			, deniedToGroups  = testDenyGroups
		);

		var callLog = mockContextPermDao.$callLog();


		super.assertEquals( 1, callLog.deleteData.len() );
		super.assertEquals( 5, callLog.insertData.len() );
	}

	function test24_hasPermission_shouldReturnTrue_whenUserBelongsToMulipleGroupsWithGivenContextPermSetAndAtLeastOneOfThoseGroupsHasExplicitGrantAccess(){
		var permsService = _getPermissionService( permissions=testPerms, roles=testRoles );
		var hasPerm      = "";
		var mockContextPerms = QueryNew( "granted,context_key", 'bit,varchar', [
			    [ 1, "somekey"          ]
			  , [ 0, "some.context.key" ]
		] );

		mockLoginService.$( "getLoggedInUserId", "me" );
		mockLoginService.$( "isSystemUser", false );

		permsService.$( "listPermissionKeys" ).$args( user="me" ).$results( [ "some.key", "another.key" ] );
		permsService.$( "listUserGroups" ).$args( user="me" ).$results( [ "somegroup", "anothergroup" ] );

		mockContextPermDao.$( "selectData" ).$args(
			  selectFields = [ "Max( granted ) as granted", "context_key" ]
			, filter       = { context = "someContext", permission_key = "a.new.key", security_group = [ "somegroup", "anothergroup" ] }
			, groupBy      = "context_key"
			, useCache     = false
		).$results( mockContextPerms );

		hasPerm = permsService.hasPermission( permissionKey="a.new.key", context="someContext", contextKeys=[ "somekey" ] );

		super.assert( hasPerm, "Should have permission, yet returned that I do not :(" );
	}

	function test25_getContextPermissions_shouldIncludeDefaultNonContextPermissions_whenIncludeDefaultPermsIsPassedAsTrue(){
		var permsService    = _getPermissionService( permissions=testPerms, roles=testRoles );
		var actual          = "";
		var mockContextPerms = QueryNew( 'permission_key,granted,security_group,group_name', 'varchar,bit,varchar,varchar', [
			  [ "assetmanager.folders.navigate", 1, "groupx", "group x" ]
			, [ "sitetree.edit"                , 1, "groupx", "group x" ]
			, [ "groupmanager.edit"            , 0, "groupy", "group y" ]
			, [ "groupmanager.edit"            , 1, "groupz", "group z" ]
			, [ "groupmanager.edit"            , 0, "groupa", "group a" ]
			, [ "groupmanager.edit"            , 1, "groupb", "group b" ]
		] );
		var mockGroups = QueryNew( "id,label,roles", "varchar,varchar,varchar", [
			  [ "anothergroup"  , "anothergrou p"  , "tester,blah"            ]
			, [ "mygroup"       , "mygrou p"       , "administrator,blah"     ]
			, [ "someothergroup", "someothergrou p", "mehrole,anothernonrole" ]
		] );

		var expected        = {
			  "sitetree.edit"                 = { granted=[{id="groupx", name="group x" }, {id="anothergroup", name="anothergrou p" }, {id="mygroup", name="mygrou p" } ], denied=[] }
			, "assetmanager.folders.navigate" = { granted=[{id="groupx", name="group x" },{id="mygroup", name="mygrou p" }], denied=[] }
			, "assetmanager.folders.read"     = { granted=[{id="anothergroup", name="anothergrou p" }, {id="mygroup", name="mygrou p" }], denied=[] }
			, "assetmanager.folders.add"      = { granted=[{id="mygroup", name="mygrou p" }], denied=[] }
			, "assetmanager.folders.edit"     = { granted=[{id="mygroup", name="mygrou p" }], denied=[] }
			, "assetmanager.assets.edit"      = { granted=[{id="mygroup", name="mygrou p" }], denied=[] }
			, "groupmanager.edit"             = { granted=[{id="groupz", name="group z" },{id="groupb", name="group b" },{id="anothergroup", name="anothergrou p" }, {id="mygroup", name="mygrou p" }], denied=[{id="groupy", name="group y" },{id="groupa", name="group a" }] }
		};
		var expandedPermKeys = [ "sitetree.edit","assetmanager.folders.navigate","assetmanager.folders.read","assetmanager.folders.add","assetmanager.folders.edit","assetmanager.assets.edit","groupmanager.edit" ];

		expandedPermKeys = expandedPermKeys.sort( "textnocase" );

		mockContextPermDao.$( "selectData" ).$args(
			  selectFields = [ "granted", "permission_key", "security_group", "security_group.label as group_name" ]
			, filter       = { context = "someContext", context_key = [ "aContextKey" ], permission_key = expandedPermKeys }
		).$results( mockContextPerms );

		mockGroupDao.$( "selectData" ).$args(
			selectFields = [ "id", "label", "roles" ]
		).$results( mockGroups );

		actual = permsService.getContextPermissions(
			  context         = "someContext"
			, contextKeys     = [ "aContextKey" ]
			, permissionKeys  = [ "assetmanager.folders.*", "!*.delete", "*.edit" ]
			, includeDefaults = true
		);

		super.assertEquals( expected, actual );
	}


// PRIVATE HELPERS
	private any function _getPermissionService( struct roles={}, struct permissions={} ) output=false {
		mockLoginService    = getMockBox().createEmptyMock( "preside.system.services.admin.LoginService" );
		cacheProvider       = _getCachebox( forceNewInstance = true ).getCache( "default" );
		mockGroupDao        = getMockBox().createEmptyMock( object = _getPresideObjectService().getObject( "security_group"              ) );
		mockUserDao         = getMockBox().createEmptyMock( object = _getPresideObjectService().getObject( "security_user"               ) );
		mockContextPermDao  = getMockBox().createEmptyMock( object = _getPresideObjectService().getObject( "security_context_permission" ) );

		return getMockBox().createMock( object=new preside.system.services.security.PermissionService(
			  loginService         = mockLoginService
			, cacheProvider        = cacheProvider
			, logger               = _getTestLogger()
			, rolesConfig          = arguments.roles
			, permissionsConfig    = arguments.permissions
			, groupDao             = mockGroupDao
			, userDao              = mockUserDao
			, contextPermDao       = mockContextPermDao
		) );
	}
}