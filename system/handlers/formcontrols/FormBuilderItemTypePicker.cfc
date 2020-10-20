component {

	property name="formBuilderItemTypesService" inject="formBuilderItemTypesService";

	public string function index( event, rc, prc, args={} ) {
		args.categories = formBuilderItemTypesService.getItemTypesByCategory();

		return renderView( view="formcontrols/formbuilderItemTypePicker/index", args=args );
	}
}