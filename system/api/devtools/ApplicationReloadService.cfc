component output=false extends="preside.system.base.Service" {

// CONSTRUCTOR
	public any function init(
		  required any coldbox
		, required any resourceBundleService
		, required any cfStaticForPreside
		, required any widgetsService
		, required any pageTypesService
		, required any pageTemplatesService
		, required any formsService
	) output=false {
		super.init( argumentCollection = arguments );

		_setColdbox( arguments.coldbox );
		_setResourceBundleService( arguments.resourceBundleService );
		_setCfStaticForPreside( arguments.cfStaticForPreside );
		_setWidgetsService( arguments.widgetsService );
		_setPageTypesService( arguments.pageTypesService );
		_setPageTemplatesService( arguments.pageTemplatesService );
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
		_getCfStaticForPreside().reload();
	}

	public void function reloadWidgets() output=false {
		_getWidgetsService().reload();
	}

	public void function reloadPageTypes() output=false {
		_getPageTypesService().reload();
	}

	public void function reloadPageTemplates() output=false {
		_getPageTemplatesService().reload();
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

	private any function _getResourceBundleService() output=false {
		return _resourceBundleService;
	}
	private void function _setResourceBundleService( required any resourceBundleService ) output=false {
		_resourceBundleService = arguments.resourceBundleService;
	}

	private any function _getCfStaticForPreside() output=false {
		return _cfStaticForPreside;
	}
	private void function _setCfStaticForPreside( required any cfStaticForPreside ) output=false {
		_cfStaticForPreside = arguments.cfStaticForPreside;
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

	private any function _getPageTemplatesService() output=false {
		return _pageTemplatesService;
	}
	private void function _setPageTemplatesService( required any pageTemplatesService ) output=false {
		_pageTemplatesService = arguments.pageTemplatesService;
	}

	private any function _getFormsService() output=false {
		return _formsService;
	}
	private void function _setFormsService( required any formsService ) output=false {
		_formsService = arguments.formsService;
	}
}