/**
 * @feature presideForms and customFields
 */
component {

	property name="enumService" inject="enumService";

	public string function index( event, rc, prc, args={} ) {
		var savedData = args.savedData ?: {};
		var kind      = Trim( savedData.kind ?: "" );
		var items    = Duplicate( enumService.listItems( args.enum ?: "customFieldCreateFlag" ) );
		var filtered = [];

		for( var item in items ) {
			var id = item.id ?: "";

			if ( id == "batch_editable" && kind != "static" ) {
				continue;
			}

			ArrayAppend( filtered, item );
		}

		args.items    = filtered;
		args.multiple = true;

		event.include( "/js/admin/specific/enumRadioList/" );

		return renderView( view="formcontrols/enumRadioList/index", args=args );
	}

}
