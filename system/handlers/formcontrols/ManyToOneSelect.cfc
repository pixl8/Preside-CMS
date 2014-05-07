component output=false {

	property name="presideObjectService" inject="presideObjectService";

	public string function index( event, rc, prc, viewletArgs={} ) output=false {
		viewletArgs.object = viewletArgs.relatedTo ?: "";

		return renderFormControl( argumentCollection=viewletArgs, type="objectPicker", layout="" );
	}
}