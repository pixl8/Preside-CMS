component extends="preside.system.base.AdminHandler" output=false {

	property name="permissionService" inject="permissionService";

	private function contextPermsForm( event, rc, prc, viewletArgs={} ) output=false {
		viewletArgs.permissionKeys = permissionService.listPermissionKeys( filter=viewletArgs.permissionKeys ?: [ "*" ] );


		return renderView( view="admin/permissions/contextPermsForm", args=viewletArgs );
	}

	function saveContextPermsAction( event, rc, prc ) output=false {

	}

}