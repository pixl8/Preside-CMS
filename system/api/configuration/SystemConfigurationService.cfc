component output=false singleton=true {

// CONSTRUCTOR
	/**
	 * @autoDiscoverDirectories.inject presidecms:directories
	 * @dao.inject                     presidecms:object:system_config
	 */
	public any function init( required array autoDiscoverDirectories, required any dao ) output=false {
		_setAutoDiscoverDirectories( arguments.autoDiscoverDirectories );
		_setDao( arguments.dao )

		reload();

		return this;
	}

// PUBLIC API METHODS
	public string function getSetting( required string category, required string setting, string default="" ) output=false {
		var result = _getDao().selectData(
			  selectFields = [ "value" ]
			, filter       = { category = arguments.category, setting = arguments.setting }
		);

		if ( result.recordCount ) {
			return result.value;
		}

		return default;
	}

	public struct function getCategorySettings( required string category ) output=false {
		var rawResult = _getDao().selectData(
			  selectFields = [ "setting", "value" ]
			, filter       = { category = arguments.category }
		);
		var result = {};

		for( var record in rawResult ){
			result[ record.setting ] = record.value;
		}

		return result;
	}

	public any function saveSetting( required string category, required string setting, required string value ) output=false  {
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

	public array function listConfigCategories() output=false {
		var categories = _getConfigCategories();
		var result    = [];

		for( var id in categories ){
			ArrayAppend( result, categories[ id ] );
		}

		return result;
	}

	public ConfigCategory function getConfigCategory( required string id ) output=false {
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

	public void function reload() output=false {
		_setConfigCategories({});
		_autoDiscoverCategories();
	}

// PRIVATE HELPERS
	private void function _autoDiscoverCategories() output=false {
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
			_registerCategory( id = LCase( id ) );
		}
	}

	private void function _registerCategory( required string id ) output=false {
		var categories = _getConfigCategories();

		categories[ arguments.id ] = new ConfigCategory(
			  id               = arguments.id
			, name             = _getConventionsBaseCategoryName( arguments.id )
			, description      = _getConventionsBaseCategoryDescription( arguments.id )
			, form             = _getConventionsBaseCategoryForm( arguments.id )
		);
	}

	private string function _getConventionsBaseCategoryName( required string id ) output=false {
		return "system-config.#arguments.id#:name";
	}
	private string function _getConventionsBaseCategoryDescription( required string id ) output=false {
		return "system-config.#arguments.id#:description";
	}
	private string function _getConventionsBaseCategoryForm( required string id ) output=false {
		return "system-config.#arguments.id#";
	}

// GETTERS AND SETTERS
	private array function _getAutoDiscoverDirectories() output=false {
		return _autoDiscoverDirectories;
	}
	private void function _setAutoDiscoverDirectories( required array autoDiscoverDirectories ) output=false {
		_autoDiscoverDirectories = arguments.autoDiscoverDirectories;
	}

	private any function _getDao() output=false {
		return _dao;
	}
	private void function _setDao( required any dao ) output=false {
		_dao = arguments.dao;
	}

	private struct function _getConfigCategories() output=false {
		return _configCategories;
	}
	private void function _setConfigCategories( required struct configCategories ) output=false {
		_configCategories = arguments.configCategories;
	}

}