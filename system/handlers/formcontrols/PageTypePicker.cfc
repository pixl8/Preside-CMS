component output=false {
	property name="pageTypesService" inject="pageTypesService";

	public string function index( event, rc, prc, viewletArgs={} ) output=false {
		viewletArgs.pageTypes = pageTypesService.listPageTypes();

		return renderView( view="formcontrols/pageTypePicker/index", args=viewletArgs );
	}
}