/**
 * @feature presideForms and sites
 */
component {

	public string function index( event, rc, prc, args={} ) output=false {
		var settings       = getSetting( "datetime.formats" );
		var dateFormatType = args.dateFormatType ?: "";
		var items          = settings[ dateFormatType ] ?: [];

		if ( !ArrayLen( items ) ) {
			return "";
		}

		args.labels = [ "" ];
		args.values = [ "" ];

		for( var item in items ) {
			ArrayAppend( args.values, item );

			var label = translateResource( uri="preside-objects.site:option.#item#.label", defaultValue="" );
			if( Len( label ) ) {
				ArrayAppend( args.labels, label );
			} else {
				label = item & " (" & DateFormat( "2025-09-20", item ) & ")";

				ArrayAppend( args.labels, label );
			}
		}

		return renderView( view="formcontrols/select/index", args=args );
	}
}