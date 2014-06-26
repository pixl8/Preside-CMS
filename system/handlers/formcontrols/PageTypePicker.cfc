component output=false {
	property name="pageTypesService" inject="pageTypesService";

	public string function index( event, rc, prc, args={} ) output=false {
		args.pageTypes = pageTypesService.listPageTypes();

		return renderView( view="formcontrols/pageTypePicker/index", args=args );
	}
}