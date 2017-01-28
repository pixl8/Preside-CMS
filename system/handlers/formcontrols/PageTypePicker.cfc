component output=false {
	property name="pageTypesService" inject="pageTypesService";

	public string function index( event, rc, prc, args={} ) output=false {
		args.values = [];
		args.labels = [];

		for( var pageType in pageTypesService.listPageTypes() ){
			args.values.append( pageType.getId() );
			args.labels.append( translateResource( pageType.getName() ) );
		}

		return renderView( view="formcontrols/select/index", args=args );
	}
}