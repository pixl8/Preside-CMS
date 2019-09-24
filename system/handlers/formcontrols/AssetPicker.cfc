component {

	property name="presideObjectService" inject="presideObjectService";
	property name="assetManagerService"  inject="AssetManagerService";

	public string function index( event, rc, prc, args={} ) output=false {
		var allowedTypes        = args.allowedTypes ?: "";
		var maxFileSize         = args.maxFileSize  ?: "";
		var savedFilters        = args.objectFilters ?: "";
		var prefetchCacheBuster = assetManagerService.getPrefetchCachebusterForAjaxSelect( ListToArray( allowedTypes ) );

		if ( Len( Trim( args.savedData.id ?: "" ) ) ) {
			var sourceObject = args.sourceObject ?: "";

			if ( Len( Trim( sourceObject ) ) && presideObjectService.isManyToManyProperty( sourceObject, args.name ) ) {
				args.savedValue = presideObjectService.selectManyToManyData(
					  objectName   = sourceObject
					, propertyName = args.name
					, id           = args.savedData.id
					, selectFields = [ "#args.name#.id" ]
				);

				args.defaultValue = args.savedValue = ValueList( args.savedValue.id );
			}
		}

		args.multiple    = args.multiple ?: ( ( args.relationship ?: "" ) == "many-to-many" );
		args.prefetchUrl = event.buildAdminLink( linkTo="assetmanager.ajaxSearchAssets", querystring="maxRows=100&allowedTypes=#allowedTypes#&savedFilters=#savedFilters#&prefetchCacheBuster=#prefetchCacheBuster#" );
		args.remoteUrl   = event.buildAdminLink( linkTo="assetmanager.ajaxSearchAssets", querystring="q=%QUERY&allowedTypes=#allowedTypes#&savedFilters=#savedFilters#" );
		args.browserUrl  = event.buildAdminLink( linkTo="assetmanager.assetPickerBrowser", querystring="allowedTypes=#allowedTypes#&savedFilters=#savedFilters#&multiple=#( args.multiple ? 'true' : 'false' )#" );
		args.uploaderUrl = event.buildAdminLink( linkTo="assetmanager.assetPickerUploader", querystring="allowedTypes=#allowedTypes#&multiple=#( args.multiple ? 'true' : 'false' )#&maxFileSize=#maxFileSize#" );

		if ( !Len( Trim( args.placeholder ?: "" ) ) ) {
			args.placeholder = translateResource(
				  uri  = "cms:datamanager.search.data.placeholder"
				, data = [ translateResource( uri=presideObjectService.getResourceBundleUriRoot( "asset" ) & "title", defaultValue=translateResource( "cms:datamanager.records" ) ) ]
			);
		}
		event.include( assetId="/js/admin/specific/assetpicker/" );
		event.include( assetId="/css/admin/specific/assetpicker/" );
		return renderView( view="formcontrols/assetPicker/index", args=args );
	}
}