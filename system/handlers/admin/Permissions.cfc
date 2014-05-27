component extends="preside.system.base.AdminHandler" output=false {

	property name="permissionService" inject="permissionService";

	private function contextPermsForm( event, rc, prc, viewletArgs={} ) output=false {
		viewletArgs.permissionKeys   = permissionService.listPermissionKeys( filter=viewletArgs.permissionKeys ?: [ "*" ] );
		viewletArgs.savedPermissions = permissionService.getContextPermissions(
			  context        = viewletArgs.context ?: ""
			, contextKeys    = [ viewletArgs.contextKey ?: "" ]
			, permissionKeys = viewletArgs.permissionKeys
		);
		viewletArgs.inheritedPermissions = permissionService.getContextPermissions(
			  context        = viewletArgs.context ?: ""
			, contextKeys    = viewletArgs.inheritedContextKeys ?: []
			, permissionKeys = viewletArgs.permissionKeys
			, includeDefaults = true
		);

		return renderView( view="admin/permissions/contextPermsForm", args=viewletArgs );
	}

	private function saveContextPermsAction( event, rc, prc ) output=false {
		for( var perm in ListToArray( rc.permissionKeys ?: "" ) ) {
			permissionService.syncContextPermissions(
				  context         = rc.context ?: ""
				, contextKey      = rc.contextKey ?: ""
				, permissionKey   = perm
				, grantedToGroups = ListToArray( rc[ "grant." & perm ] ?: "" )
				, deniedToGroups  = ListToArray( rc[ "deny." & perm ] ?: "" )
			);
		}

		return true;
	}

}