component {

	property name="presideObjectService" inject="presideObjectService";

	public string function default( event, rc, prc, args={} ){
		var objectId = args.data ?: "";

		if ( presideObjectService.objectExists( objectId ) ) {
			var uriRoot    = presideObjectService.getResourceBundleUriRoot( objectId );
			var isPageType = presideObjectService.isPageType( objectId );
			var fullUri    = uriRoot & ( isPageType ? "name" : "title.singular" );

			return translateResource( uri=fullUri, defaultValue=objectId );
		}

		return "";
	}

}