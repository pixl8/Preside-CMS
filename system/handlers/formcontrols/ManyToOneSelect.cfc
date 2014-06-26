component output=false {

	property name="presideObjectService" inject="presideObjectService";

	public string function index( event, rc, prc, args={} ) output=false {
		args.object = args.relatedTo ?: "";

		return renderFormControl( argumentCollection=args, type="objectPicker", layout="" );
	}
}