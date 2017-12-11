component {

	property name="adminDataViewsService" inject="adminDataViewsService";
	property name="presideObjectService"  inject="presideObjectService";

	public string function adminView( event, rc, prc, args={} ){
		var fkId          = args.data         ?: "";
		var objectName    = args.objectName   ?: "";
		var propertyName  = args.propertyName ?: "";
		var recordId      = args.recordId     ?: "";
		var fkObjectName  = "asset";

		if ( !fkId.len() ) {
			return "";
		}

		fkObjectName = presideObjectService.getObjectPropertyAttribute(
			  objectName    = objectName
			, propertyName  = propertyName
			, attributeName = "relatedto"
			, defaultValue  = propertyName
		);

		if ( adminDataViewsService.doesObjectHaveBuildAdminLinkHandler( fkObjectName ) ) {
			args.recordLink = adminDataViewsService.buildViewObjectRecordLink( fkObjectName, fkId );
		}
		args.renderedAsset = renderAsset( assetId=fkId, args={ derivative="icon" } );

		return renderView( view="/renderers/content/asset/adminView", args=args );


	}

}