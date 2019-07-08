/**
 * @singleton
 * @presideservice
 *
 */
component {

// CONSTRUCTOR

	/**
	 * @coldbox.inject                        coldbox
	 * @presideObjectService.inject           presideObjectService
	 * @resourceBundleService.inject          resourceBundleService
	 * @stickerForPreside.inject              stickerForPreside
	 * @delayedStickerRendererService.inject  delayedStickerRendererService
	 * @widgetsService.inject                 widgetsService
	 * @pageTypesService.inject               pageTypesService
	 * @formsService.inject                   formsService
	 * @itemTypesService.inject               formbuilderItemTypesService
	 */
	public any function init(
		  required any coldbox
		, required any presideObjectService
		, required any resourceBundleService
		, required any stickerForPreside
		, required any delayedStickerRendererService
		, required any widgetsService
		, required any pageTypesService
		, required any formsService
		, required any itemTypesService
	) {

		_setColdbox( arguments.coldbox );
		_setPresideObjectService( arguments.presideObjectService );
		_setResourceBundleService( arguments.resourceBundleService );
		_setStickerForPreside( arguments.stickerForPreside );
		_setDelayedStickerRendererService( arguments.delayedStickerRendererService );
		_setWidgetsService( arguments.widgetsService );
		_setPageTypesService( arguments.pageTypesService );
		_setFormsService( arguments.formsService );
		_setItemTypesService( arguments.itemTypesService );

		return this;
	}

// PUBLIC API METHODS
	public void function gracefulShutdown( boolean force=false ) {
		var lockName = "gracefulshutdownlock-#ExpandPath( '/' )#";

		lock name=lockName type="exclusive" timeout=0 {
			$systemOutput( "Attempting graceful application shutdown..." );
			$announceInterception( "onApplicationEnd" );
			$getColdbox().getWirebox().shutdownSingletons( arguments.force );
			$systemOutput( "Gracefull application shutdown complete" );
		}
	}

	public void function reloadAll() {
		gracefulShutdown();

		application.clear();
	}

	public void function clearCaches() {
		_getColdbox().getCachebox().clearAll();
		$announceInterception( "onClearCaches", {} );
	}

	public void function dbSync() {
		_getPresideObjectService().dbSync();
	}

	public void function reloadPresideObjects() {
		_getPresideObjectService().reload();
	}

	public void function reloadI18n() {
		_getResourceBundleService().reload();
	}

	public void function reloadStatic() {
		_getStickerForPreside().init( coldbox=_getColdbox(), delayedStickerRendererService=_getDelayedStickerRendererService() );
	}

	public void function reloadWidgets() {
		_getWidgetsService().reload();
	}

	public void function reloadPageTypes() {
		_getPageTypesService().reload();
	}

	public void function reloadForms() {
		_getFormsService().reload();
		_getItemTypesService().clearCachedItemTypeConfig();
	}


// GETTERS AND SETTERS
	private any function _getColdbox() {
		return _coldbox;
	}
	private void function _setColdbox( required any coldbox ) {
		_coldbox = arguments.coldbox;
	}

	private any function _getPresideObjectService() {
		return _PresideObjectService;
	}
	private void function _setPresideObjectService( required any PresideObjectService ) {
		_PresideObjectService = arguments.PresideObjectService;
	}

	private any function _getResourceBundleService() {
		return _resourceBundleService;
	}
	private void function _setResourceBundleService( required any resourceBundleService ) {
		_resourceBundleService = arguments.resourceBundleService;
	}

	private any function _getStickerForPreside() {
		return _stickerForPreside;
	}
	private void function _setStickerForPreside( required any stickerForPreside ) {
		_stickerForPreside = arguments.stickerForPreside;
	}

	private any function _getDelayedStickerRendererService() {
		return _delayedStickerRendererService;
	}
	private void function _setDelayedStickerRendererService( required any delayedStickerRendererService ) {
		_delayedStickerRendererService = arguments.delayedStickerRendererService;
	}

	private any function _getWidgetsService() {
		return _widgetsService;
	}
	private void function _setWidgetsService( required any widgetsService ) {
		_widgetsService = arguments.widgetsService;
	}

	private any function _getPageTypesService() {
		return _pageTypesService;
	}
	private void function _setPageTypesService( required any pageTypesService ) {
		_pageTypesService = arguments.pageTypesService;
	}

	private any function _getFormsService() {
		return _formsService;
	}
	private void function _setFormsService( required any formsService ) {
		_formsService = arguments.formsService;
	}

	private any function _getItemTypesService() {
		return _itemTypesService;
	}
	private void function _setItemTypesService( required any itemTypesService ) {
		_itemTypesService = arguments.itemTypesService;
	}
}