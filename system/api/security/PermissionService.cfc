component output=false extends="preside.system.base.Service" {

// CONSTRUCTOR
	public any function init( required struct permissionsConfig, required struct rolesConfig ) output=false {
		super.init( argumentCollection = arguments );

		_parseConfiguredRolesAndPermissions( arguments.permissionsConfig, arguments.rolesConfig );

		return this;
	}

// PUBLIC API METHODS
	public array function listRoles() output=false {
		return _getRoles().keyArray();
	}

	public array function listPermissionKeys() output=false {
		return _getPermissions();
	}

// PRIVATE HELPERS
	private void function _parseConfiguredRolesAndPermissions( required struct permissionsConfig, required struct rolesConfig ) output=false {
		var expandedPermissions = _expandPermissions( arguments.permissionsConfig );


		_setPermissions( expandedPermissions );
		_setRoles( arguments.rolesConfig );
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
}