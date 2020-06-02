component {
	property name="enumService" inject="enumService";

	public string function index( event, rc, prc, args={} ) {
		var enum  = args.enum ?: "";
		var items = enumService.listItems( enum );

		args.labels       = [ "" ];
		args.values       = [ "" ];

		if ( !items.len() ) {
		    return "";
		}

		for( var item in items ) {
		    args.values.append( item.id    );
			args.labels.append( item.label );
		}

		return renderView( view="formcontrols/select/index", args=args );

	}
}