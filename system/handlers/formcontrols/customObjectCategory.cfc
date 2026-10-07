/**
 * @feature admin and customObjects
 */
component {

	property name="customObjectsService" inject="delayedInjector:customObjectsService";

	public string function index( event, rc, prc, args={} ) {
		args.categories = [];

		try {
			args.categories = customObjectsService.listCategorySuggestions();
		} catch ( any e ) {}

		return renderView( view="formcontrols/customObjectCategory/index", args=arguments.args );
	}

}
