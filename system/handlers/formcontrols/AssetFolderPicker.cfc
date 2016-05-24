component output=false {

	property name="assetManagerService" inject="assetManagerService";

	public string function index( event, rc, prc, args={} ) {
		var prefetchCacheBuster = assetManagerService.getAssetFolderPrefetchCachebusterForAjaxSelect();

		args.object  = "asset_folder";

		args.prefetchUrl = event.buildAdminLink(
			  linkTo      = "assetManager.getFoldersForAjaxSelectControl"
			, querystring = "maxRows=100&prefetchCacheBuster=#prefetchCacheBuster#"
		);
		args.remoteUrl = args.remoteUrl ?: event.buildAdminLink(
			  linkTo      = "assetManager.getFoldersForAjaxSelectControl"
			, querystring = "q=%QUERY"
		);

		return renderView( view="formcontrols/objectPicker/index", args=args );
	}
}