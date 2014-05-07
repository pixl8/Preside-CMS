component output=false {
	property name="pageTemplatesService" inject="pageTemplatesService";

	public string function index( event, rc, prc, viewletArgs={} ) output=false {
		viewletArgs.templates = pageTemplatesService.listTemplates();

		return renderView( view="formcontrols/templatePicker/index", args=viewletArgs );
	}
}