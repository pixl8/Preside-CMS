/**
 * @feature presideForms and admin
 */
component {
	property name="permissionService" inject="permissionService";

	public string function index( event, rc, prc, args={} ) output=false {
		args.groupedRoles = permissionService.listRolesWithGroup();

		return renderView( view="formcontrols/rolepicker/index", args=args );
	}
}