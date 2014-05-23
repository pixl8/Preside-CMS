component output=false extends="preside.system.base.Service" {

// CONSTRUCTOR
	public any function init( required any loginService, required struct permissionsConfig, required struct rolesConfig ) output=false {
		super.init( argumentCollection = arguments );

		_setLoginService( arguments.loginService );

		_denormalizeAndSaveConfiguredRolesAndPermissions( arguments.permissionsConfig, arguments.rolesConfig );

		return this;
	}

// PUBLIC API METHODS
	public array function listRoles() output=false {
		return _getRoles().keyArray();
	}

	public array function listPermissionKeys( string role="", string group="", string user="" ) output=false {
		if ( Len( Trim( arguments.role ) ) ) {
			return _getRolePermissions( arguments.role );

		} elseif ( Len( Trim( arguments.group ) ) ) {
			return _getGroupPermissions( arguments.group );

		} elseif ( Len( Trim( arguments.user ) ) ) {
			return _getUserPermissions( arguments.user );
		}

		return _getPermissions();
	}

	public boolean function hasPermission(
		  required string permissionKey
		,          string context       = ""
		,          array  contextKeys   = []
		,          string userId        = _getLoginService().getLoggedInUserId()
	) output=false {

		if ( Len( Trim( arguments.context ) ) && arguments.contextKeys.len() ) {
			var contextPerm = _getContextPermission( argumentCollection=arguments );
			if ( !IsNull( contextPerm ) && IsBoolean( contextPerm ) ) {
				return contextPerm;
			}
		}

		if ( arguments.userId == _getLoginService().getLoggedInUserId() && _getLoginService().isSystemUser() ) {
			return true;
		}

		return listPermissionKeys( user=arguments.userId ).find( arguments.permissionKey );
	}

// PRIVATE HELPERS
	private void function _denormalizeAndSaveConfiguredRolesAndPermissions( required struct permissionsConfig, required struct rolesConfig ) output=false {
		_setPermissions( _expandPermissions( arguments.permissionsConfig ) );
		_setRoles( _expandRoles( arguments.rolesConfig ) );
	}

	private array function _getRolePermissions( required string role ) output=false {
		var roles = _getRoles();

		return roles[ arguments.role ] ?: [];
	}

	private array function _getGroupPermissions( required string group ) output=false {
		var roles = _getPresideObjectService().selectData( objectName="security_group", id=arguments.group, selectFields=[ "roles" ] );
		var perms = [];

		if ( !roles.recordCount ) {
			return [];
		}
		for( var role in ListToArray( roles.roles ) ){
			_getRolePermissions( role ).each( function( perm ){
				if ( !perms.find( perm ) ) {
					perms.append( perm );
				}
			} );
		}

		return perms;
	}

	private array function _getUserPermissions( required string user ) output=false {
		var perms = [];
		var groups = _getPresideObjectService().selectManyToManyData(
			  objectName   = "security_user"
			, propertyName = "groups"
			, id           = arguments.user
			, selectFields = [ "security_group" ]
		);

		for( var group in groups ){
			_getGroupPermissions( group.security_group ).each( function( perm ){
				if ( !perms.find( perm ) ) {
					perms.append( perm );
				}
			} );
		}

		return perms;
	}

	private any function _getContextPermission(
		  required string userId
		, required string permissionKey
		, required string context
		, required array  contextKeys
	) {
		var perms = _getPresideObjectService().selectData(
			  objectName   = "security_user"
			, selectFields = [ "security_context_permission.granted", "security_context_permission.context_key" ]
			, forceJoins   = "inner"
			, filter       = {
				  "security_user.id"                           = arguments.userId
				, "security_context_permission.permission_key" = arguments.permissionKey
				, "security_context_permission.context"        = arguments.context
				, "security_context_permission.context_key"    = arguments.contextKeys
			}
		);

		if ( !perms.recordCount ) {
			return NullValue();
		}

		if ( perms.recordCount == 1 ) {
			return perms.granted;
		}

		var permsAsStruct = {};
		for( var perm in perms ) {
			permsAsStruct[ perm.context_key ] = perm.granted;
		}
		for( var key in arguments.contextKeys ){
			if ( permsAsStruct.keyExists( key ) ) {
				return permsAsStruct[ key ];
			}
		}

		return NullValue();
	}

	private array function _expandPermissions( required struct permissions, string prefix="" ) output=false {
		var expanded = [];

		for( var perm in permissions ){
			var newPrefix = ListAppend( arguments.prefix, perm, "." );

			if ( IsStruct( permissions[ perm ] ) ) {
				var childPerms = _expandPermissions( permissions[ perm ], newPrefix );
				for( var childPerm in childPerms ){
					expanded.append( childPerm );
				}
			} elseif ( IsArray( permissions[ perm ] ) ) {
				for( var key in permissions[ perm ] ) {
					if ( IsSimpleValue( key ) ) {
						expanded.append( ListAppend( newPrefix, key, "." ) );
					}
				}
			}
		}

		return expanded;
	}

	private struct function _expandRoles( required struct roles ) output=false {
		var expandedRoles = {};

		for( var roleName in arguments.roles ){
			var role = arguments.roles[ roleName ];
			var exclusions = [];

			expandedRoles[ roleName ] = [];

			if ( IsArray( role ) ) {
				for( var permissionKey in role ){
					if ( IsSimpleValue( permissionKey ) ) {
						if ( Left( permissionKey, 1 ) == "!" ) {
							exclusions.append( ReReplace( permissionKey, "^!(.*)$", "\1" ) );
						} elseif ( Find( "*", permissionKey ) ) {
							( _expandWildCardPermissionKey( permissionKey ) ).each( function( expandedKey ){
								if ( !expandedRoles[ roleName ].findNoCase( expandedKey ) ) {
									expandedRoles[ roleName ].append( expandedKey );
								}
							} );
						} else {
							expandedRoles[ roleName ].append( permissionKey );
						}
					}
				}
			}

			for( var exclusion in exclusions ){
				if ( Find( "*", exclusion ) ) {
					( _expandWildCardPermissionKey( exclusion ) ).each( function( expandedKey ){
						expandedRoles[ roleName ].delete( expandedKey );
					} );
				} else {
					expandedRoles[ roleName ].delete( exclusion );
				}
			}
		}

		return expandedRoles;
	}

	private array function _expandWildCardPermissionKey( required string permissionKey ) output=false {
		var regex       = Replace( _reEscape( arguments.permissionKey ), "\*", "(.*?)", "all" );
		var permissions = _getPermissions();

		return permissions.filter( function( permKey ){
			return ReFindNoCase( regex, permKey );
		} );
	}

	private string function _reEscape( required string stringToEscape ) output=false {
		var charsToEscape = [ "\", "$","{","}","(",")","<",">","[","]","^",".","*","+","?","##",":","&" ];
		var escaped       = arguments.stringToEscape;

		for( var char in charsToEscape ){
			escaped = Replace( escaped, char, "\" & char, "all" );
		}

		return escaped;
	}

// GETTERS AND SETTERS
	private struct function _getRoles() output=false {
		return _roles;
	}
	private void function _setRoles( required struct roles ) output=false {
		_roles = arguments.roles;
	}

	private array function _getPermissions() output=false {
		return _permissions;
	}
	private void function _setPermissions( required array permissions ) output=false {
		_permissions = arguments.permissions;
	}

	private any function _getLoginService() output=false {
		return _loginService;
	}
	private void function _setLoginService( required any loginService ) output=false {
		_loginService = arguments.loginService;
	}
}