component {
	property name="presideRestService" inject="presideRestService";

	public string function index( event, rc, prc, args={} ) {
		args.apis = presideRestService.listApis();

		return renderView( view="formcontrols/restApiPicker/index", args=args );
	}
}