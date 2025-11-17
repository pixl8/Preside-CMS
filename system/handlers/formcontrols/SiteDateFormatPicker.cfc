/**
 * @feature presideForms and sites
 */
component {

	property name="i18n"              inject="i18n";

	public string function index( event, rc, prc, args={} ) output=false {
		var settings       = getSetting( "datetime.formats" );
		var dateFormatType = args.dateFormatType ?: "";
		var items          = settings[dateFormatType];
		args.labels        = [ "" ];
		args.values        = [ "" ];

		if ( !items.len() ) {
		    return "";
		}

		for( var item in items ) {
			var label = translateResource(uri="preside-objects.site_localisation:option.#item#.label", defaultValue="");
			args.values.append( item );
			args.labels.append( Len(label) ? label: item );
		}
		
		return renderView( view="formcontrols/select/index", args=args );
	}
}