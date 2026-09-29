/**
 * @feature presideForms and customFields
 */
component {

	property name="customFieldsService" inject="customFieldsService";

	public string function index( event, rc, prc, args={} ) {
		var savedData    = args.savedData ?: {};
		var targetObject = savedData.target_object ?: ( rc.target_object ?: "" );
		var inputName    = args.name ?: "";

		args.targetObject      = targetObject;
		args.nodes             = Len( targetObject ) ? customFieldsService.listRelatedDataTreeNodes( targetObject ) : [];
		args.relationshipValue = args.defaultValue ?: "";
		args.propertyValue     = savedData.related_data_property ?: ( rc.related_data_property ?: "" );
		args.propertyInputName = ReReplaceNoCase( inputName, "relationship$", "property" );
		args.fetchUrl          = event.buildAdminLink( linkTo="customFields.fetchRelatedDataTreeNodes" );
		args.selectionLabel    = ( Len( targetObject ) && Len( args.relationshipValue ) && Len( args.propertyValue ) ) ? customFieldsService.getRelatedDataSelectionLabel(
			  objectName       = targetObject
			, relationshipPath = args.relationshipValue
			, propertyName     = args.propertyValue
		) : "";

		return renderView( view="formcontrols/customFieldRelatedDataTree/index", args=args );
	}

}
