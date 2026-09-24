/**
 * @feature presideForms and customFields and rulesEngine
 */
component {

	property name="customFieldsService" inject="customFieldsService";

	public string function index( event, rc, prc, args={} ) {
		var savedData = args.savedData ?: {};
		var fieldId   = savedData.field ?: "";

		if ( !Len( Trim( fieldId ) ) && ( rc.relationshipKey ?: "" ) == "field" ) {
			fieldId = rc.parentId ?: "";
		}
		if ( !Len( Trim( fieldId ) ) ) {
			fieldId = rc.field ?: "";
		}

		if ( Len( Trim( fieldId ) ) ) {
			var field = customFieldsService.getField( fieldId );
			args.filterObject = field.target_object ?: "";
		}

		if ( !Len( Trim( args.filterObject ?: "" ) ) ) {
			return "";
		}

		return renderViewlet( event="formcontrols.filterPicker.index", args=args );
	}

}
