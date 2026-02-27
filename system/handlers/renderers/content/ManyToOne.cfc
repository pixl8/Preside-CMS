component {

	property name="presideObjectService" inject="presideObjectService";
	property name="labelRendererService" inject="labelRendererService";

	public string function adminView( event, rc, prc, args={} ){
		var fkId          = args.data         ?: "";
		var objectName    = args.objectName   ?: "";
		var propertyName  = args.propertyName ?: "";
		var recordId      = args.recordId     ?: "";
		var fkObjectName  = "";
		var labelRenderer = "";

		if ( !Len( fkId ) ) {
			return "";
		}

		fkObjectName = presideObjectService.getObjectPropertyAttribute(
			  objectName    = objectName
			, propertyName  = propertyName
			, attributeName = "relatedto"
			, defaultValue  = propertyName
		);
		labelRenderer = presideObjectService.getObjectAttribute( fkObjectName, "labelRenderer" );

		if( Len( fkObjectName ) && presideObjectService.dataExists( objectName=fkObjectName, id=fkId ) ){
			args.recordLink  = event.buildAdminLink( objectName=fkObjectName, recordId=fkId );
			args.recordLabel = renderLabel( objectName=fkObjectName, recordId=fkId, labelRenderer=labelRenderer );
			args.labelIsHtml = labelRendererService.rendersHtml( labelRenderer );
		}

		return renderView( view="/renderers/content/manyToOne/adminView", args=args );
	}

}
