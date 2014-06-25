component output=false singleton=true {

// CONSTRUCTOR

	/**
	 * @coldbox.inject               coldbox
	 * @presideObjectService.inject  PresideObjectService
	 * @resourceBundleService.inject ResourceBundleService
	 * @stickerForPreside.inject     coldbox:myplugin:stickerForPreside
	 * @widgetsService.inject        WidgetsService
	 * @pageTypesService.inject      PageTypesService
	 * @formsService.inject          FormsService
	 */
	public any function init(
		  required any coldbox
		, required any presideObjectService
		, required any resourceBundleService
		, required any stickerForPreside
		, required any widgetsService
		, required any pageTypesService
		, required any formsService
	) output=false {

		_setColdbox( arguments.coldbox );
		_setPresideObjectService( arguments.presideObjectService );
		_setResourceBundleService( arguments.resourceBundleService );
		_setStickerForPreside( arguments.stickerForPreside );
		_setWidgetsService( arguments.widgetsService );
		_setPageTypesService( arguments.pageTypesService );
		_setFormsService( arguments.formsService );

		return this;
	}

// PUBLIC API METHODS
	public void function reloadAll() output=false {
		var currentBootstrap = application.cbBootstrap;
		var newBootstrap     = new preside.system.coldboxModifications.Bootstrap(
			  COLDBOX_CONFIG_FILE   = currentBootstrap.getCOLDBOX_CONFIG_FILE()
			, COLDBOX_APP_ROOT_PATH = currentBootstrap.getCOLDBOX_APP_ROOT_PATH()
			, COLDBOX_APP_KEY       = currentBootstrap.getCOLDBOX_APP_KEY()
			, COLDBOX_APP_MAPPING   = currentBootstrap.getCOLDBOX_APP_MAPPING()
		);

		newBootstrap.loadColdbox();

		application.cbBootstrap = newBootstrap;
	}

	public void function clearCaches() output=false {
		_getColdbox().getCachebox().clearAll();
	}

	public void function dbSync() output=false {
		_getPresideObjectService().dbSync();
	}

	public void function reloadPresideObjects() output=false {
		_getPresideObjectService().reload();
	}

	public void function reloadI18n() output=false {
		_getResourceBundleService().reload();
	}

	public void function reloadStatic() output=false {
		_getStickerForPreside().init( _getColdbox() );
	}

	public void function reloadWidgets() output=false {
		_getWidgetsService().reload();
	}

	public void function reloadPageTypes() output=false {
		_getPageTypesService().reload();
	}

	public void function reloadForms() output=false {
		_getFormsService().reload();
	}


// GETTERS AND SETTERS
	private any function _getColdbox() output=false {
		return _coldbox;
	}
	private void function _setColdbox( required any coldbox ) output=false {
		_coldbox = arguments.coldbox;
	}

	private any function _getPresideObjectService() output=false {
		return _PresideObjectService;
	}
	private void function _setPresideObjectService( required any PresideObjectService ) output=false {
		_PresideObjectService = arguments.PresideObjectService;
	}

	private any function _getResourceBundleService() output=false {
		return _resourceBundleService;
	}
	private void function _setResourceBundleService( required any resourceBundleService ) output=false {
		_resourceBundleService = arguments.resourceBundleService;
	}

	private any function _getStickerForPreside() output=false {
		return _stickerForPreside;
	}
	private void function _setStickerForPreside( required any stickerForPreside ) output=false {
		_stickerForPreside = arguments.stickerForPreside;
	}

	private any function _getWidgetsService() output=false {
		return _widgetsService;
	}
	private void function _setWidgetsService( required any widgetsService ) output=false {
		_widgetsService = arguments.widgetsService;
	}

	private any function _getPageTypesService() output=false {
		return _pageTypesService;
	}
	private void function _setPageTypesService( required any pageTypesService ) output=false {
		_pageTypesService = arguments.pageTypesService;
	}

	private any function _getFormsService() output=false {
		return _formsService;
	}
	private void function _setFormsService( required any formsService ) output=false {
		_formsService = arguments.formsService;
	}
}