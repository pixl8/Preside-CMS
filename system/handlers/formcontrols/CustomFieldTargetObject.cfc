/**
 * @feature presideForms and customFields
 */
component {

	property name="customFieldsService" inject="customFieldsService";

	public string function index( event, rc, prc, args={} ) {
		var options = customFieldsService.listEnabledObjectOptions();

		args.values = [ "" ];
		args.labels = [ "" ];

		for( var option in options ) {
			ArrayAppend( args.values, option.id );
			ArrayAppend( args.labels, option.label );
		}

		return renderView( view="formcontrols/select/index", args=args );
	}

}
