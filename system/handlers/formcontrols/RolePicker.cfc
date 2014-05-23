component output=false {
	property name="permissionService" inject="permissionService";

	public string function index( event, rc, prc, viewletArgs={} ) output=false {
		var roleIds = permissionService.listRoles();

		viewletArgs.values = "";
		viewletArgs.labels = "";

		for( var roleId in roleIds ){
			viewletArgs.values = ListAppend( viewletArgs.values, roleId );
			viewletArgs.labels = ListAppend( viewletArgs.labels, translateResource( uri="roles:#roleId#.title", defaultValue=roleId ) );
		}

		return renderView( view="formcontrols/select/index", args=viewletArgs );
	}
}