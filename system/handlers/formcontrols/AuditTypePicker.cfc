component {

	property name="auditService" inject="auditService";

	public string function index( event, rc, prc, args={} ) output=false {
		var types = auditService.getLoggedTypes();
		var typesWithTitles = [];

		args.values = [ "" ];
		args.labels = [ "" ];

		for( var type in types ){
			typesWithTitles.append({
				  label = translateResource( uri="auditlog.#type#:title", defaultValue=type )
				, value = type
			});
		}

		typesWithTitles.sort( function( a, b ){
			return a.label < b.label ? -1 : 1;
		} );

		for( var type in typesWithTitles ){
			args.labels.append( type.label );
			args.values.append( type.value );
		}

		return renderView( view="formcontrols/select/index", args=args );
	}
}