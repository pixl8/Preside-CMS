component output=false {
	property name="permissionService" inject="permissionService";

	public string function index( event, rc, prc, args={} ) output=false {
		args.roles = permissionService.listRoles();

		return renderView( view="formcontrols/rolepicker/index", args=args );
	}
}