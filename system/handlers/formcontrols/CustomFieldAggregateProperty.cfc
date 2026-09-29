/**
 * @feature presideForms and customFields
 */
component {

	property name="customFieldsService" inject="customFieldsService";

	public string function index( event, rc, prc, args={} ) {
		var savedData    = args.savedData ?: {};
		var targetObject = savedData.target_object ?: ( rc.target_object ?: "" );
		var candidates   = Len( targetObject ) ? customFieldsService.listAggregateCandidateProperties( targetObject ) : [];

		args.values = [ "" ];
		args.labels = [ "" ];
		for( var candidate in candidates ) {
			ArrayAppend( args.values, candidate.id );
			ArrayAppend( args.labels, candidate.label );
		}

		return renderView( view="formcontrols/select/index", args=args );
	}

}
