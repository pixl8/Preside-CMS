/**
 * @feature presideForms and customFields
 */
component {

	property name="customFieldsService"  inject="customFieldsService";
	property name="presideObjectService" inject="presideObjectService";

	public string function index( event, rc, prc, args={} ) {
		var savedData         = args.savedData ?: {};
		var aggregateProperty = savedData.aggregate_property ?: "";
		var targetObject      = savedData.target_object ?: ( rc.target_object ?: "" );
		var relatedObject     = "";

		if ( Len( Trim( aggregateProperty ) ) && Len( Trim( targetObject ) ) ) {
			relatedObject = presideObjectService.getObjectPropertyAttribute(
				  objectName    = targetObject
				, propertyName  = aggregateProperty
				, attributeName = "relatedTo"
				, defaultValue  = ""
			);
		}

		var candidates = Len( relatedObject ) ? customFieldsService.listNumericRelatedProperties( relatedObject ) : [];

		args.values = [ "" ];
		args.labels = [ "" ];
		for( var candidate in candidates ) {
			ArrayAppend( args.values, candidate.id );
			ArrayAppend( args.labels, candidate.label );
		}

		return renderView( view="formcontrols/select/index", args=args );
	}

}
