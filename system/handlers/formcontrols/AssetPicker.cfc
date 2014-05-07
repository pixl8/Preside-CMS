component output=false {

	property name="presideObjectService" inject="presideObjectService";

	public string function index( event, rc, prc, viewletArgs={} ) output=false {
		var allowedTypes = viewletArgs.allowedTypes ?: "";

		if ( Len( Trim( viewletArgs.savedData.id ?: "" ) ) ) {
			var sourceObject = viewletArgs.sourceObject ?: "";

			if ( presideObjectService.isManyToManyProperty( sourceObject, viewletArgs.name ) ) {
				viewletArgs.savedValue = presideObjectService.selectManyToManyData(
					  objectName   = sourceObject
					, propertyName = viewletArgs.name
					, id           = viewletArgs.savedData.id
					, selectFields = [ "#viewletArgs.name#.id" ]
				);

				viewletArgs.defaultValue = viewletArgs.savedValue = ValueList( viewletArgs.savedValue.id );
			}
		}

		viewletArgs.multiple    = viewletArgs.multiple ?: ( ( viewletArgs.relationship ?: "" ) == "many-to-many" );
		viewletArgs.prefetchUrl = event.buildAdminLink( linkTo="assetmanager.getAssetsForAjaxPicker", querystring="allowedTypes=#allowedTypes#" );
		viewletArgs.remoteUrl   = event.buildAdminLink( linkTo="assetmanager.getAssetsForAjaxPicker", querystring="q=%QUERY&allowedTypes=#allowedTypes#" );
		viewletArgs.browserUrl  = event.buildAdminLink( linkTo="assetmanager.assetPickerBrowser", querystring="allowedTypes=#allowedTypes#&multiple=#( viewletArgs.multiple ? 'true' : 'false' )#" );

		if ( !Len( Trim( viewletArgs.placeholder ?: "" ) ) ) {
			viewletArgs.placeholder = translateResource(
				  uri  = "cms:datamanager.search.data.placeholder"
				, data = [ translateResource( uri=presideObjectService.getResourceBundleUriRoot( "asset" ) & "title", defaultValue=translateResource( "cms:datamanager.records" ) ) ]
			);
		}

		return renderView( view="formcontrols/assetPicker/index", args=viewletArgs );
	}
}