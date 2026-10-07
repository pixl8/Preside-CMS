/**
 * @feature admin and customObjects
 */
component {

	property name="customObjectsService" inject="delayedInjector:customObjectsService";
	property name="customFieldsService"  inject="delayedInjector:customFieldsService";

	public string function index( event, rc, prc, args={} ) {
		var savedData  = args.savedData ?: {};
		var objectKey  = Trim( savedData.key ?: "" );
		var objectName = Len( objectKey ) ? customObjectsService.getObjectName( objectKey ) : "";
		var chosen     = Trim( savedData.label_field ?: "" );

		args.values = [];
		args.labels = [];


		if ( Len( objectName ) ) {
			for ( var field in customFieldsService.listFields( objectName=objectName, includeInactive=true ) ) {
				var fieldKey = Trim( field.key ?: "" );
				if ( !Len( fieldKey ) || CompareNoCase( fieldKey, "label" ) == 0 ) {
					continue;
				}

				ArrayAppend( args.values, fieldKey );
				ArrayAppend( args.labels, Len( Trim( field.label ?: "" ) ) ? field.label : fieldKey );
			}
		}

		return renderView( view="formcontrols/select/index", args=args );
	}

}
