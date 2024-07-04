/**
 * Service that provides API methods for dealing with CMS admin permissions.
 * See [[cmspermissioning]] for a full guide to CMS users and permissions.
 *
 * @singleton      true
 * @presideService true
 * @autodoc        true
 * @feature        admin
 *
 */
component displayName="Admin permissions service" {

// CONSTRUCTOR
	/**
	 * @loginService.inject       LoginService
	 * @bundleService.inject      delayedInjector:ResourceBundleService
	 * @cacheProvider.inject      cachebox:PermissionsCache
	 * @permissionsConfig.inject  coldbox:setting:adminPermissions
	 * @rolesConfig.inject        coldbox:setting:adminRoles
	 * @groupDao.inject           presidecms:object:security_group
	 * @userDao.inject            presidecms:object:security_user
	 * @contextPermDao.inject     presidecms:object:security_context_permission
	 */
	public any function init(
		  required any    loginService
		, required any    bundleService
		, required any    cacheProvider
		, required struct permissionsConfig
		, required struct rolesConfig
		, required any    groupDao
		, required any    userDao
		, required any    contextPermDao
	) {
		_setLoginService( arguments.loginService );
		_setBundleService( arguments.bundleService );
		_setCacheProvider( arguments.cacheProvider );
		_setGroupDao( arguments.groupDao );
		_setUserDao( arguments.userDao );
		_setContextPermDao( arguments.contextPermDao );
		_denormalizeAndSaveConfiguredRolesAndPermissions( arguments.permissionsConfig, arguments.rolesConfig );

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Returns an array of admin user role names
	 * that have been configured for the application.
	 * \n
	 * See [[cmspermissioning]] for a full guide to CMS users and permissions.
	 *
	 * @autodoc
	 *
	 */
	public array function listRoles() {
		return _getRoles().keyArray();
	}

	public struct function listRolesWithGroup() {
		var cacheKey  = "admin-roles-with-group";
		var fromCache = _getCacheProvider().get( cacheKey );

		if ( !IsNull( local.fromCache ) ) {
			return fromCache;
		}

		var grouped = {};
		var roles   = listRoles();

		for ( var role in roles ) {
			var roleGroup = _getBundleService().getResource( uri="roles:#role#.group" );

			if ( len( trim( roleGroup ) ) ) {
				grouped[ roleGroup ] = grouped[ roleGroup ] ?: [];
				arrayAppend( grouped[ roleGroup ], role );
			} else {
				grouped[ "__nogroup" ] = grouped[ "__nogroup" ] ?: [];
				arrayAppend( grouped[ "__nogroup" ], role );
			}
		}

		_getCacheProvider().set( cacheKey, grouped );
		return grouped;
	}

	/**
	 * Returns an array of permission keys that apply to the
	 * given arguments.
	 * \n
	 * See [[cmspermissioning]] for a full guide to CMS users and permissions.
	 *
	 * @autodoc
	 * @role.hint   If supplied, the method will return permission keys that the role has access to
	 * @group.hint  If supplied, the method will return permission keys that the group has access to
	 * @user.hint   If supplied, the method will return permission keys that the user has access to
	 * @filter.hint An array of filters with which to filter permission keys
	 *
	 */
	public array function listPermissionKeys( string role="", string group="", string user="", array filter=[] ) {
		if ( Len( Trim( arguments.role ) ) ) {
			return _getRolePermissions( arguments.role );

		} else if ( Len( Trim( arguments.group ) ) ) {
			return _getGroupPermissions( arguments.group );

		} else if ( Len( Trim( arguments.user ) ) ) {
			return _getUserPermissions( arguments.user );
		} else if ( arguments.filter.len() ) {
			return _filterPermissions( arguments.filter );
		}

		return _getPermissions();
	}

	/**
	 * Returns whether or not the user has permission to the given
	 * set of keys.
	 * \n
	 * See [[cmspermissioning]] for a full guide to CMS users and permissions.
	 *
	 * @autodoc
	 * @permissionKey.hint The permission key as defined in `Config.cfc`
	 * @context.hint       Optional named context
	 * @contextKeys.hint   Array of keys for the given context (required if context supplied)
	 * @userId.hint        ID of the user whose permissions we wish to check
	 * @userId.docdefault  ID of logged in user
	 *
	 */
	public boolean function hasPermission(
		  required string permissionKey
		,          string context       = ""
		,          array  contextKeys   = []
		,          string userId        = _getLoginService().getLoggedInUserId()
	) {
		var cacheKey = "hasPermission-#arguments.userId#-#arguments.permissionKey#-#arguments.context#-#ArrayToList( arguments.contextKeys )#";
		var fromCache = _getCacheProvider().get( cacheKey );

		if ( !IsNull( local.fromCache ) ) {
			return fromCache;
		}

		var hasPermission = NullValue();

		if ( !Len( Trim( arguments.userId ) ) ) {
			hasPermission = false;
		} else if ( arguments.userId == _getLoginService().getLoggedInUserId() && _getLoginService().isSystemUser() ) {
			hasPermission = true;
		} else if ( Len( Trim( arguments.context ) ) && arguments.contextKeys.len() ) {
			var contextPerm = _getContextPermission( argumentCollection=arguments );
			if ( !IsNull( local.contextPerm ) && IsBoolean( contextPerm ) ) {
				hasPermission = contextPerm;
			}
		}

		if ( IsNull( local.hasPermission ) ) {
			hasPermission = ArrayFind( listPermissionKeys( user=arguments.userId ), LCase( arguments.permissionKey ) ) > 0;
		}

		_getCacheProvider().set( cacheKey, hasPermission )

		return hasPermission;
	}

	/**
	 * Returns whether or not the user has permission to the given
	 * set of keys. Returns a struct with permission keys as keys
	 * and boolean values for whether user has permission for each
	 * key.
	 * \n
	 * See [[cmspermissioning]] for a full guide to CMS users and permissions.
	 *
	 * @autodoc
	 * @permissionKeys.hint The permission keys as defined in `Config.cfc`
	 * @context.hint        Optional named context
	 * @contextKeys.hint    Array of keys for the given context (required if context supplied)
	 * @userId.hint         ID of the user whose permissions we wish to check
	 * @userId.docdefault   ID of logged in user
	 *
	 */
	public struct function hasPermissions(
		  required array  permissionKeys
		,          string context       = ""
		,          array  contextKeys   = []
		,          string userId        = _getLoginService().getLoggedInUserId()
	) {
		var result = {};
		var keysWithoutContext = [];
		for( var key in arguments.permissionKeys ) {
			result[ key ] = false;
		}

		if ( Len( Trim( arguments.userId ) ) ) {
			if ( arguments.userId == _getLoginService().getLoggedInUserId() && _getLoginService().isSystemUser() ) {
				for( var key in arguments.permissionKeys ) {
					result[ key ] = true;
				}
			} else {
				if ( Len( Trim( arguments.context ) ) && arguments.contextKeys.len() ) {
					var contextPerms = _getMultiContextPermissions( argumentCollection=arguments );
					for( var key in result ) {
						if ( StructKeyExists( contextPerms, key ) ) {
							result[ key ] = IsBoolean( local.contextPerms[ key ] ) && local.contextPerms[ key ];
						} else {
							keysWithoutContext.append( key );
						}
					}
				}

				if ( keysWithoutContext.len() ) {
					request._userPermissionKeys = request._userPermissionKeys ?: listPermissionKeys( user=arguments.userId );
					for( var key in keysWithoutContext ) {
						local.result[ key ] = ArrayFindNoCase( request._userPermissionKeys, key );
					}
				}
			}
		}

		return result;
	}

	/**
	 * Returns whether or not the user has any permission to the given
	 * set of keys.
	 * \n
	 * See [[cmspermissioning]] for a full guide to CMS users and permissions.
	 *
	 * @autodoc
	 * @permissionKeys.hint The permission keys as defined in `Config.cfc`
	 * @context.hint        Optional named context
	 * @contextKeys.hint    Array of keys for the given context (required if context supplied)
	 * @userId.hint         ID of the user whose permissions we wish to check
	 * @userId.docdefault   ID of logged in user
	 *
	 */
	public boolean function hasAnyPermissions(
		  required array  permissionKeys
		,          string context       = ""
		,          array  contextKeys   = []
		,          string userId        = _getLoginService().getLoggedInUserId()
	) {
		if ( !ArrayLen( arguments.permissionKeys ) ) {
			return true;
		}

		for ( var permissionKey in permissionKeys ) {
			if ( hasPermission( argumentCollection=arguments, permissionKey=permissionKey ) ) {
				return true;
			}
		}

		return false;
	}

	/**
	 * Returns an array of user group IDs that the user is a member of
	 *
	 * @autodoc
	 * @userId.hint ID of the user whose groups we wish to get
	 * @includeCatchAll.hint Whether or not to include the 'catch all' group
	 *
	 */
	public array function listUserGroups( required string userId, boolean includeCatchAll=true ) {
		var catchAllIndex = 0;
		var groups = _getUserDao().selectManyToManyData(
			  propertyName = "groups"
			, id           = arguments.userId
			, selectFields = [ "groups.id", "is_catch_all" ]
		);

		for( var i=1; i<=groups.recordCount; i++ ) {
			if ( IsBoolean( groups.is_catch_all[ i ] ) && groups.is_catch_all[ i ] ) {
				catchAllIndex = i;
				break;
			}
		}
		groups = ValueArray( groups.id );

		if ( arguments.includeCatchAll && !catchAllIndex ) {
			var catchAllGroups = _getGroupDao().selectData(
				  selectFields = [ "id" ]
				, filter       = { is_catch_all=true }
			);

			ArrayAppend( groups, ValueArray( catchAllGroups.id ), true );
		} else if ( !arguments.includeCatchAll && catchAllIndex ) {
			ArrayDeleteAt( groups, catchAllIndex );
		}

		return groups;
	}

	public array function listUserGroupsRoles( required string userId ) {
		var cacheKey = "userGroupsRoles-#arguments.userId#";
		var fromCache = _getCacheProvider().get( cacheKey );
		if ( !isNull( local.fromCache ) ) {
			return fromCache;
		}

		var groupsRoles = [];
		var userGroups  = listUserGroups( argumentCollection=arguments );

		if ( arrayLen( userGroups ) ) {
			var rolesQuery = _getGroupDao().selectData(
				  filter       = { id=userGroups }
				, selectFields = [ "roles" ]
			);

			for ( var q in rolesQuery ) {
				for ( var role in listToArray( q.roles ) ) {
					groupsRoles.append( role );
				}
			}
		}

		_getCacheProvider().set( cacheKey, groupsRoles );

		return groupsRoles;
	}

	public boolean function userHasAssignedRoles(
		  required string userId
		, required array  roles
	) {
		var cacheKey = "userRoles-#arguments.userId#-#hash( serialize( arguments.roles ) )#";
		var fromCache = _getCacheProvider().get( cacheKey );
		if ( !isNull( local.fromCache ) ) {
			return fromCache;
		}

		var hasPermission = false;
		var userRoles     = listUserGroupsRoles( userId=arguments.userId );

		for ( var role in arguments.roles ) {
			if ( arrayContains( userRoles, role ) ) {
				hasPermission = true;
				break;
			}
		}

		_getCacheProvider().set( cacheKey, hasPermission );

		return hasPermission;
	}

	public struct function getContextPermissions(
		  required string  context
		, required array   contextKeys
		, required array   permissionKeys
		,          boolean includeDefaults=false
	) {
		var expandedPermissionKeys = listPermissionKeys( filter=permissionKeys );
		var contextPerms           = {};
		var dbData                 = "";

		for( var key in expandedPermissionKeys ){
			contextPerms[ key ] = {
				  granted = []
				, denied  = []
			};
		}

		if ( arguments.contextKeys.len() ) {
			dbData = _getContextPermDao().selectData(
				  selectFields = [ "granted", "permission_key", "security_group", "security_group.label as group_name" ]
				, filter       = {
					  context        = arguments.context
					, context_key    = arguments.contextKeys
					, permission_key = expandedPermissionKeys.sort( "textnocase" )
				  }
			);

			for( var record in dbData ){
				if ( record.granted ) {
					contextPerms[ record.permission_key ].granted.append( { id=record.security_group, name=record.group_name } );
				} else {
					contextPerms[ record.permission_key ].denied.append( { id=record.security_group, name=record.group_name } );
				}
			}
		}


		if ( arguments.includeDefaults ) {
			for( key in contextPerms ) {
				_getDefaultGroupsForPermission( permissionKey=key ).each( function( group ){
					if ( !contextPerms[ key ].granted.findNoCase( group ) ) {
						contextPerms[ key ].granted.append( group );
					}
				} );
			}
		}

		return contextPerms;
	}

	public boolean function syncContextPermissions( required string context, required string contextKey, required string permissionKey, required array grantedToGroups, required array deniedToGroups ) {
		transaction {
			_getContextPermDao().deleteData(
				filter = {
					  context        = arguments.context
					, context_key    = arguments.contextKey
					, permission_key = arguments.permissionKey
				}
			);

			for( var group in arguments.grantedToGroups ){
				_getContextPermDao().insertData(
					data = {
						  context        = arguments.context
						, context_key    = arguments.contextKey
						, permission_key = arguments.permissionKey
						, security_group = group
						, granted        = true
					}
				);
			}

			for( var group in arguments.deniedToGroups ){
				_getContextPermDao().insertData(
					data = {
						  context        = arguments.context
						, context_key    = arguments.contextKey
						, permission_key = arguments.permissionKey
						, security_group = group
						, granted        = false
					}
				);
			}

			_getCacheProvider().clearAll();
		}

		return true;
	}

	public void function setupCatchAllGroup() {
		var groupDao = _getGroupDao();
		if ( !groupDao.dataExists( filter={ is_catch_all=true } ) ) {
			groupDao.insertData({
				  label        = $translateResource( "preside-objects.security_group:catch_all_group.name" )
				, description  = $translateResource( "preside-objects.security_group:catch_all_group.description" )
				, is_catch_all = true
			});
		}
	}

	public boolean function isCatchAllGroup( required string groupid ) {
		return _getGroupDao().dataExists( id=arguments.groupid, extraFilters=[{ filter={ is_catch_all=true } }] );
	}

	/**
	 * Returns whether or not the given permission key exists.
	 * Useful for dynamic permissions checking where you may
	 * wish to fall back to another check when the permission
	 * does not exist.
	 *
	 * @permissionKey.hint The permission key you wish to check, e.g. blog.share
	 */
	public boolean function permissionExists( required string permissionkey ) {
		return ArrayFindNoCase( _getPermissions(), arguments.permissionKey );
	}

// PRIVATE HELPERS
	private void function _denormalizeAndSaveConfiguredRolesAndPermissions( required struct permissionsConfig, required struct rolesConfig ) {
		_setPermissions( _expandPermissions( arguments.permissionsConfig ) );
		_setRoles( _expandRoles( arguments.rolesConfig ) );
	}

	private array function _getRolePermissions( required string role ) {
		var roles = _getRoles();

		return roles[ arguments.role ] ?: [];
	}

	private array function _getGroupPermissions( required string group ) {
		var roles = _getGroupDao().selectData( id=arguments.group, selectFields=[ "roles" ] );
		var perms = [];

		if ( !roles.recordCount ) {
			return [];
		}
		for( var role in ListToArray( roles.roles ) ){
			_getRolePermissions( role ).each( function( perm ){
				if ( !perms.findNoCase( perm ) ) {
					perms.append( perm );
				}
			} );
		}

		return perms;
	}

	private array function _getUserPermissions( required string user ) {
		var cacheKey = "_userPermissionsCache#arguments.user#";
		var fromCache = _getCacheProvider().get( cacheKey );

		if ( !IsNull( local.fromCache ) ) {
			return fromCache;
		}

		var perms = [];

		for( var group in listUserGroups( arguments.user ) ){
			var groupPerms = _getGroupPermissions( group );
			for( var perm in groupPerms ) {
				if ( !ArrayFind( perms, LCase( perm ) ) ) {
					ArrayAppend( perms, LCase( perm ) );
				}
			}
		}

		_getCacheProvider().set( cacheKey, perms );

		return perms;
	}

	private array function _filterPermissions( required array filter ) {
		var filtered   = [];
		var exclusions = [];
		var allPerms   = _getPermissions();

		for( var permissionKey in filter ){
			if ( IsSimpleValue( permissionKey ) ) {
				if ( Left( permissionKey, 1 ) == "!" ) {
					exclusions.append( ReReplace( permissionKey, "^!(.*)$", "\1" ) );

				} else if ( permissionKey contains "*" ) {
					( _expandWildCardPermissionKey( permissionKey ) ).each( function( expandedKey ){
						if ( !filtered.findNoCase( expandedKey ) ) {
							filtered.append( expandedKey );
						}
					} );
				} else if ( allPerms.findNoCase( permissionKey ) && !filtered.findNoCase( permissionKey ) ) {
					filtered.append( permissionKey );
				}
			}
		}

		for( var exclusion in exclusions ){
			if ( exclusion contains "*" ) {
				( _expandWildCardPermissionKey( exclusion ) ).each( function( expandedKey ){
					filtered.delete( expandedKey );
				} );
			} else {
				filtered.delete( exclusion );
			}
		}

		return filtered;
	}

	private any function _getContextPermission(
		  required string userId
		, required string permissionKey
		, required string context
		, required array  contextKeys
	) {
		var args         = arguments;
		var userGroups   = listUserGroups( arguments.userId );
		var cacheKey     = "ContextPermKeysForPermContextAndGroup: " & Hash( arguments.context & arguments.permissionKey & userGroups.toList() );
		var cache        = _getCacheProvider();
		var contextPerms = cache.get( cacheKey );

		if ( IsNull( local.contextPerms ) ) {
			contextPerms = {};

			var permsFromDb  = _getContextPermDao().selectData(
				  selectFields = [ "granted", "context_key" ]
				, filter       = { context = args.context, permission_key = args.permissionKey, security_group = userGroups }
				, orderBy      = "context_key, granted"
				, useCache     = false
			);

			for( var perm in permsFromDb ){
				contextPerms[ perm.context_key ] = perm.granted;
			}

			cache.set( cacheKey, contextPerms );
		}


		if ( contextPerms.isEmpty() ) {
			return;
		}

		for( var key in arguments.contextKeys ){
			if ( StructKeyExists( contextPerms, key ) ) {
				return contextPerms[ key ];
			}
		}

		return;
	}

	private struct function _getMultiContextPermissions(
		  required string userId
		, required array  permissionKeys
		, required string context
		, required array  contextKeys
	) {
		var result       = {};
		var args         = arguments;
		var userGroups   = listUserGroups( arguments.userId );
		var cacheKey     = "MultiContextPermKeysForPermContextAndGroup: " & Hash( arguments.context & arguments.permissionKeys.toList() & userGroups.toList() );
		var cache        = _getCacheProvider();
		var contextPerms = cache.get( cacheKey );

		if ( IsNull( local.contextPerms ) ) {
			contextPerms = {};
			var permsFromDb  = _getContextPermDao().selectData(
				  selectFields = [ "granted", "context_key", "permission_key" ]
				, filter       = { context = args.context, permission_key = args.permissionKeys, security_group = userGroups }
				, orderBy      = "context_key, granted"
				, useCache     = false
			);

			for( var perm in permsFromDb ){
				contextPerms[ perm.context_key ] = contextPerms[ perm.context_key ] ?: {};
				contextPerms[ perm.context_key ][ perm.permission_key ] = perm.granted;
			}

			cache.set( cacheKey, contextPerms );
		}

		if ( contextPerms.isEmpty() ) {
			return result;
		}

		for( var contextKey in arguments.contextKeys ){
			if ( StructKeyExists( contextPerms, contextKey ) ) {
				for( var permKey in contextPerms[ contextKey ] ) {
					if ( !StructKeyExists( result, permKey ) ) {
						result[ permKey ] = contextPerms[ contextKey ][ permKey ];
					}
				}
			}
		}

		return result;
	}

	private array function _expandPermissions( required struct permissions, string prefix="" ) {
		var expanded = [];

		for( var perm in permissions ){
			var newPrefix = ListAppend( arguments.prefix, perm, "." );

			if ( IsStruct( permissions[ perm ] ) ) {
				var childPerms = _expandPermissions( permissions[ perm ], newPrefix );
				for( var childPerm in childPerms ){
					expanded.append( childPerm );
				}
			} else if ( IsArray( permissions[ perm ] ) ) {
				for( var key in permissions[ perm ] ) {
					if ( IsSimpleValue( key ) ) {
						expanded.append( ListAppend( newPrefix, key, "." ) );
					}
				}
			}
		}

		return expanded;
	}

	private struct function _expandRoles( required struct roles ) {
		var expandedRoles = StructNew( "linked" );

		for( var roleName in arguments.roles ){
			var role = arguments.roles[ roleName ];
			var exclusions = [];

			expandedRoles[ roleName ] = [];

			if ( IsArray( role ) ) {
				expandedRoles[ roleName ] = listPermissionKeys( filter=role );
			}
		}

		return expandedRoles;
	}

	private array function _expandWildCardPermissionKey( required string permissionKey ) {
		var regex       = "^" & Replace( _reEscape( arguments.permissionKey ), "\*", "(.*?)", "all" ) & "$";
		var permissions = _getPermissions();

		return permissions.filter( function( permKey ){
			return ReFindNoCase( regex, permKey );
		} );
	}

	private string function _reEscape( required string stringToEscape ) {
		var charsToEscape = [ "\", "$","{","}","(",")","<",">","[","]","^",".","*","+","?","##",":","&" ];
		var escaped       = arguments.stringToEscape;

		for( var char in charsToEscape ){
			escaped = Replace( escaped, char, "\" & char, "all" );
		}

		return escaped;
	}

	private array function _getDefaultGroupsForPermission( required string permissionKey ) {
		var roles         = _getRoles();
		var rolesWithPerm = {};
		var groups        = [];

		for( var role in roles ){
			if ( roles[ role ].findNoCase( arguments.permissionKey ) ) {
				rolesWithPerm[ role ] = 1;
			}
		}

		if ( StructCount( rolesWithPerm ) ) {
			var allGroups = _getGroupDao().selectData(
				selectFields = [ "id", "label", "roles" ]
			);

			for( var group in allGroups ){
				for ( var role in ListToArray( group.roles ) ) {
					if ( StructKeyExists( rolesWithPerm, role ) ) {
						groups.append( { id=group.id, name=group.label } );
						break;
					}
				}
			}
		}

		return groups;
	}

// GETTERS AND SETTERS
	private struct function _getRoles() {
		return _roles;
	}
	private void function _setRoles( required struct roles ) {
		_roles = arguments.roles;
	}

	private array function _getPermissions() {
		return _permissions;
	}
	private void function _setPermissions( required array permissions ) {
		_permissions = arguments.permissions;
	}

	private any function _getLoginService() {
		return _loginService;
	}
	private void function _setLoginService( required any loginService ) {
		_loginService = arguments.loginService;
	}

	private any function _getBundleService() {
		return _bundleService;
	}
	private void function _setBundleService( required any bundleService ) {
		_bundleService = arguments.bundleService;
	}

	private any function _getCacheProvider() {
		return _cacheProvider;
	}
	private void function _setCacheProvider( required any cacheProvider ) {
		_cacheProvider = arguments.cacheProvider;
	}

	private any function _getGroupDao() {
		return _groupDao;
	}
	private void function _setGroupDao( required any groupDao ) {
		_groupDao = arguments.groupDao;
	}

	private any function _getUserDao() {
		return _userDao;
	}
	private void function _setUserDao( required any userDao ) {
		_userDao = arguments.userDao;
	}

	private any function _getContextPermDao() {
		return _contextPermDao;
	}
	private void function _setContextPermDao( required any contextPermDao ) {
		_contextPermDao = arguments.contextPermDao;
	}
}