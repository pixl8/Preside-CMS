component {
	property name="enumService" inject="enumService";

	public string function index( event, rc, prc, args={} ) {
		var enum  = args.enum ?: "";

		args.items = enumService.listItems( enum );
		if ( !args.items.len() ) {
		    return "";
		}

		return renderView( view="formcontrols/enumRadioList/index", args=args );
	}
}