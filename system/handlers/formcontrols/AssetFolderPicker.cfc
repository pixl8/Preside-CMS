component {

	property name="assetManagerService" inject="assetManagerService";

	public string function index( event, rc, prc, args={} ) {
		var prefetchCacheBuster = assetManagerService.getAssetFolderPrefetchCachebusterForAjaxSelect();
		var excludeDescendants  = args.excludeDescendants ?: "";

		args.object = "asset_folder";

		args.prefetchUrl = event.buildAdminLink(
			  linkTo      = "assetManager.getFoldersForAjaxSelectControl"
			, querystring = "maxRows=100&prefetchCacheBuster=#prefetchCacheBuster#&excludeDescendants=#excludeDescendants#"
		);
		args.remoteUrl = args.remoteUrl ?: event.buildAdminLink(
			  linkTo      = "assetManager.getFoldersForAjaxSelectControl"
			, querystring = "excludeDescendants=#excludeDescendants#&q=%QUERY"
		);

		return renderView( view="formcontrols/objectPicker/index", args=args );
	}
}