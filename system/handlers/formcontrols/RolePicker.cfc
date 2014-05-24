component output=false {
	property name="permissionService" inject="permissionService";

	public string function index( event, rc, prc, viewletArgs={} ) output=false {
		viewletArgs.roles = permissionService.listRoles();

		return renderView( view="formcontrols/rolepicker/index", args=viewletArgs );
	}
}