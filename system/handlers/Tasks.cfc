/**
 * Core system tasks that are used with the task manager system
 *
 */
component {

	property name="assetManagerService" inject="assetManagerService";

	/**
	 * For a given folder or asset, ensures that all associated files
	 * reside in the correct public/private data store and have appropriately
	 * set URLs (public vs private).
	 *
	 * @displayName  Move asset files
	 * @schedule     disabled
	 * @displayGroup assetmanager
	 * @timeout      1200
	 *
	 */
	private boolean function moveAssets( event, rc, prc, logger, args={} ) {
		return assetManagerService.ensureAssetsAreInCorrectLocation(
			  folderId = args.folder  ?: ""
			, assetId  = args.assetId ?: ""
			, logger = ( logger ?: NullValue() )
		);
	}
}