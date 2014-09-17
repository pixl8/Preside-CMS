component output=false {
	property name="websitePermissionService" inject="websitePermissionService";

	public string function index( event, rc, prc, args={} ) output=false {
		args.permissions = websitePermissionService.listPermissionKeys();

		return renderView( view="formcontrols/websitePermissionsPicker/index", args=args );
	}
}