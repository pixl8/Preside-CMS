component output=false {

	property name="presideObjectService" inject="presideObjectService";
	property name="dataManagerService"   inject="dataManagerService";

	public string function index( event, rc, prc, viewletArgs={} ) output=false {
		var prefetchCacheBuster = dataManagerService.getPrefetchCachebusterForAjaxSelect( "page" );

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
		viewletArgs.prefetchUrl = event.buildAdminLink( linkTo="sitetree.getPagesForAjaxPicker", querystring="prefetchCacheBuster=#prefetchCacheBuster#" );
		viewletArgs.remoteUrl   = event.buildAdminLink( linkTo="sitetree.getPagesForAjaxPicker", querystring="q=%QUERY" );

		if ( !Len( Trim( viewletArgs.placeholder ?: "" ) ) ) {
			viewletArgs.placeholder = translateResource(
				  uri  = "cms:datamanager.search.data.placeholder"
				, data = [ translateResource( uri=presideObjectService.getResourceBundleUriRoot( "page" ) & "title", defaultValue=translateResource( "cms:datamanager.records" ) ) ]
			);
		}

		return renderView( view="formcontrols/sitetreePagePicker/index", args=viewletArgs );
	}
}