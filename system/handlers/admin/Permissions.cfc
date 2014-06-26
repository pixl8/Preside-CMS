component extends="preside.system.base.AdminHandler" output=false {

	property name="permissionService" inject="permissionService";

	private function contextPermsForm( event, rc, prc, args={} ) output=false {
		args.permissionKeys   = permissionService.listPermissionKeys( filter=args.permissionKeys ?: [ "*" ] );
		args.savedPermissions = permissionService.getContextPermissions(
			  context        = args.context ?: ""
			, contextKeys    = [ args.contextKey ?: "" ]
			, permissionKeys = args.permissionKeys
		);
		args.inheritedPermissions = permissionService.getContextPermissions(
			  context        = args.context ?: ""
			, contextKeys    = args.inheritedContextKeys ?: []
			, permissionKeys = args.permissionKeys
			, includeDefaults = true
		);

		return renderView( view="admin/permissions/contextPermsForm", args=args );
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