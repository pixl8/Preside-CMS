/**
 * @feature admin and customFields
 */
component {

	property name="presideObjectService" inject="presideObjectService";

	public string function index( event, rc, prc, args={} ) {
		return adminView( argumentCollection=arguments );
	}

	public string function admin( event, rc, prc, args={} ) {
		return adminView( argumentCollection=arguments );
	}

	public string function adminDataTable( event, rc, prc, args={} ) {
		return adminView( argumentCollection=arguments );
	}

	public string function adminView( event, rc, prc, args={} ) {
		var ids          = ListToArray( Trim( args.data ?: "" ) );
		var objectName   = args.objectName   ?: "";
		var propertyName = args.propertyName ?: "";
		var relatedTo    = "";
		var links        = [];

		if ( !ArrayLen( ids ) ) {
			return "";
		}

		relatedTo = presideObjectService.getObjectPropertyAttribute(
			  objectName    = objectName
			, propertyName  = propertyName
			, attributeName = "relatedto"
			, defaultValue  = ""
		);

		for ( var id in ids ) {
			if ( !Len( Trim( id ) ) ) {
				continue;
			}

			var recordLabel = Len( relatedTo ) ? renderLabel( relatedTo, id ) : id;
			var recordLink  = Len( relatedTo ) ? event.buildAdminLink( objectName=relatedTo, recordId=id ) : "";

			if ( Len( recordLink ) ) {
				ArrayAppend( links, '<a href="#recordLink#">#recordLabel#</a>' );
			} else {
				ArrayAppend( links, recordLabel );
			}
		}

		return ArrayToList( links, ", " );
	}

}
