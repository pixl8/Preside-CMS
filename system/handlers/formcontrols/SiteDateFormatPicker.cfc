/**
 * @feature presideForms and sites
 */
component {

	property name="i18n"              inject="i18n";

	public string function index( event, rc, prc, args={} ) output=false {
		var settings       = getSetting( "datetime.formats" );
		var dateFormatType = args.dateFormatType ?: ""		
		var items          = settings[dateFormatType] ?: [];
		args.labels        = [ "" ];
		args.values        = [ "" ];
		
		if ( !ArrayLen(items) ) {
			return "";
		}

		for( var item in items ) {
			ArrayAppend(args.values, item);

			var label = translateResource(uri="preside-objects.site:option.#item#.label", defaultValue="");
			if( Len(label) ) {
				ArrayAppend(args.labels, label);
			} else {
				label = item & " (" & DateFormat("2025-09-20", item) & ")";
				ArrayAppend(args.labels, label);
			}
		}
		
		return renderView( view="formcontrols/select/index", args=args );
	}
}