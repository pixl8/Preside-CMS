/**
 * @feature presideForms and customFields
 */
component {

	property name="customFieldsService" inject="customFieldsService";

	public string function index( event, rc, prc, args={} ) {
		var savedData    = args.savedData ?: {};
		var targetObject = savedData.target_object ?: ( rc.target_object ?: "" );
		var slots        = Len( targetObject ) ? customFieldsService.listSlots( targetObject ) : [ { id="custom", label="custom" } ];

		if ( ArrayLen( slots ) <= 1 ) {
			args.type  = "hidden";
			args.value = slots[ 1 ].id ?: "custom";
			return renderView( view="formcontrols/hidden/index", args=args );
		}

		args.values = [];
		args.labels = [];
		for( var slot in slots ) {
			ArrayAppend( args.values, slot.id );
			ArrayAppend( args.labels, slot.label );
		}

		return renderView( view="formcontrols/select/index", args=args );
	}

}
