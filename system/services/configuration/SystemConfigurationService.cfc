/**
 * @singleton true
 */
component {

// CONSTRUCTOR
	/**
	 * @autoDiscoverDirectories.inject presidecms:directories
	 * @dao.inject                     presidecms:object:system_config
	 * @injectedConfig.inject          coldbox:setting:injectedConfig
	 * @formsService.inject            formsService
	 */
	public any function init( required array autoDiscoverDirectories, required any dao, required struct injectedConfig, required any formsService ) {
		_setAutoDiscoverDirectories( arguments.autoDiscoverDirectories );
		_setDao( arguments.dao )
		_setInjectedConfig( arguments.injectedConfig );
		_setFormsService( arguments.formsService );

		reload();

		return this;
	}

// PUBLIC API METHODS
	public string function getSetting( required string category, required string setting, string default="" ) {
		var injected = _getInjectedConfig();
		var result   = _getDao().selectData(
			  selectFields = [ "value" ]
			, filter       = { category = arguments.category, setting = arguments.setting }
		);

		if ( result.recordCount ) {
			return result.value;
		}

		return injected[ "#arguments.category#.#arguments.setting#" ] ?: arguments.default;
	}

	public struct function getCategorySettings( required string category ) {
		var rawResult = _getDao().selectData(
			  selectFields = [ "setting", "value" ]
			, filter       = { category = arguments.category }
		);
		var result = {};
		var injectedStartsWith = "#arguments.category#.";

		for( var record in rawResult ){
			result[ record.setting ] = record.value;
		}

		var injected = _getInjectedConfig().filter( function( key ){ return key.startsWith( injectedStartsWith ) } );
		for( var key in injected ) {
			var setting = ListRest( key, "." );

			if ( !result.keyExists( setting ) ) {
				result[ setting ] = injected[ key ];
			}
		}

		return result;
	}

	public any function saveSetting( required string category, required string setting, required string value )  {
		var dao = _getDao();

		transaction {
			var currentRecord = dao.selectData(
				  selectFields = [ "id" ]
				, filter       = { category = arguments.category, setting = arguments.setting }
			);

			if ( currentRecord.recordCount ) {
				return dao.updateData(
					  data = { value = arguments.value }
					, id   = currentRecord.id
				);
			} else {
				return dao.insertData(
					data = { category = arguments.category, setting = arguments.setting, value = arguments.value }
				);
			}
		}
	}

	public array function listConfigCategories() {
		var categories = _getConfigCategories();
		var result    = [];

		for( var id in categories ){
			ArrayAppend( result, categories[ id ] );
		}

		return result;
	}

	public ConfigCategory function getConfigCategory( required string id ) {
		var categories = _getConfigCategories();

		if ( categories.keyExists( arguments.id ) ) {
			return categories[ arguments.id ];
		}

		categories = categories.keyArray();
		categories.sort( "textnocase" );
		categories = SerializeJson( categories );

		throw(
			  type    = "SystemConfigurationService.category.notFound"
			, message = "The configuration category [#arguments.id#] could not be found. Configured categories are: #categories#"
		);
	}

	public void function reload() {
		_setConfigCategories({});
		_autoDiscoverCategories();
	}

// PRIVATE HELPERS
	private void function _autoDiscoverCategories() {
		var objectsPath             = "/forms/system-config";
		var ids                     = {};
		var autoDiscoverDirectories = _getAutoDiscoverDirectories();

		for( var dir in autoDiscoverDirectories ) {
			dir   = ReReplace( dir, "/$", "" );
			var objects = DirectoryList( dir & objectsPath, false, "query", "*.xml" );

			for ( var obj in objects ) {
				if ( obj.type eq "File" ) {
					ids[ ReReplace( obj.name, "\.xml$", "" ) ] = true;
				}
			}
		}

		for( var id in ids ) {
			if ( _getFormsService().formExists( formName="system-config." & id, checkSiteTemplates=false ) ) {
				_registerCategory( id = LCase( id ) );
			}
		}
	}

	private void function _registerCategory( required string id ) {
		var categories = _getConfigCategories();

		categories[ arguments.id ] = new ConfigCategory(
			  id               = arguments.id
			, name             = _getConventionsBaseCategoryName( arguments.id )
			, description      = _getConventionsBaseCategoryDescription( arguments.id )
			, icon             = _getConventionsBaseCategoryIcon( arguments.id )
			, form             = _getConventionsBaseCategoryForm( arguments.id )
		);
	}

	private string function _getConventionsBaseCategoryName( required string id ) {
		return "system-config.#arguments.id#:name";
	}
	private string function _getConventionsBaseCategoryDescription( required string id ) {
		return "system-config.#arguments.id#:description";
	}
	private string function _getConventionsBaseCategoryIcon( required string id ) {
		return "system-config.#arguments.id#:iconClass";
	}
	private string function _getConventionsBaseCategoryForm( required string id ) {
		return "system-config.#arguments.id#";
	}

// GETTERS AND SETTERS
	private array function _getAutoDiscoverDirectories() {
		return _autoDiscoverDirectories;
	}
	private void function _setAutoDiscoverDirectories( required array autoDiscoverDirectories ) {
		_autoDiscoverDirectories = arguments.autoDiscoverDirectories;
	}

	private any function _getDao() {
		return _dao;
	}
	private void function _setDao( required any dao ) {
		_dao = arguments.dao;
	}

	private struct function _getConfigCategories() {
		return _configCategories;
	}
	private void function _setConfigCategories( required struct configCategories ) {
		_configCategories = arguments.configCategories;
	}

	private struct function _getInjectedConfig() {
		return _injectedConfig;
	}
	private void function _setInjectedConfig( required struct injectedConfig ) {
		_injectedConfig = arguments.injectedConfig;
	}

	private struct function _getFormsService() {
		return _formsService;
	}
	private void function _setFormsService( required struct formsService ) {
		_formsService = arguments.formsService;
	}
}