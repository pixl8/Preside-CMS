/**
 * @feature admin and customFields
 */
component {

	property name="customFieldsService"  inject="customFieldsService";
	property name="presideObjectService" inject="presideObjectService";

	public string function admin( event, rc, prc, args={} ) {
		return index( argumentCollection=arguments );
	}

	public string function adminView( event, rc, prc, args={} ) {
		return index( argumentCollection=arguments );
	}

	public string function index( event, rc, prc, args={} ) {
		var value        = args.data         ?: "";
		var objectName   = args.objectName   ?: "";
		var propertyName = args.propertyName ?: "";

		if ( !Len( Trim( value ) ) ) {
			return "";
		}

		var fieldId = presideObjectService.getObjectPropertyAttribute(
			  objectName    = objectName
			, propertyName  = propertyName
			, attributeName = "customFieldId"
		);
		if ( !Len( Trim( fieldId ) ) ) {
			return EncodeForHTML( value );
		}

		var options = customFieldsService.listLookupOptions( fieldId );
		for( var option in options ) {
			if ( option.id == value ) {
				return EncodeForHTML( option.label );
			}
		}

		return EncodeForHTML( value );
	}

}
