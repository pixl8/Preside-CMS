component {

	property name="presideObjectService"  inject="presideObjectService";

	public string function adminView( event, rc, prc, args={} ){
		var fkId          = args.data         ?: "";
		var objectName    = args.objectName   ?: "";
		var propertyName  = args.propertyName ?: "";
		var recordId      = args.recordId     ?: "";
		var fkObjectName  = "";

		if ( !Len( fkId ) ) {
			return "";
		}

		fkObjectName = presideObjectService.getObjectPropertyAttribute(
			  objectName    = objectName
			, propertyName  = propertyName
			, attributeName = "relatedto"
			, defaultValue  = propertyName
		);

		args.recordLink = event.buildAdminLink( objectName=fkObjectName, recordId=fkId );
		args.recordLabel = renderLabel( fkObjectName, fkId );

		return renderView( view="/renderers/content/manyToOne/adminView", args=args );


	}

}