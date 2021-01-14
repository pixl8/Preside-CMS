component {

	property name="presideObjectService" inject="presideObjectService";

	private string function default( event, rc, prc, args={} ){
		var objectId = args.data ?: "";

		if ( presideObjectService.objectExists( objectId ) ) {
			var uriRoot    = presideObjectService.getResourceBundleUriRoot( objectId );
			var isPageType = presideObjectService.isPageType( objectId );
			var fullUri    = uriRoot & ( isPageType ? "name" : "title.singular" );

			return translateResource( uri=fullUri, defaultValue=objectId );
		}

		return "";
	}

	private string function admindatatable( event, rc, prc, args={} ){
		var objectId = args.data ?: "";

		if ( presideObjectService.objectExists( objectId ) ) {
			var uriRoot    = presideObjectService.getResourceBundleUriRoot( objectId );
			var isPageType = presideObjectService.isPageType( objectId );
			var fullUri    = uriRoot & ( isPageType ? "name" : "title.singular" );
			var objectLabel = translateResource( uri=fullUri, defaultValue=objectId );
			var objectIcon  = translateResource( uri=uriRoot & "iconClass", defaultValue="fa-database" );
			return '<i class="fa fa-fw #objectIcon#"></i> ' & objectLabel;
		}

		return "";
	}

}