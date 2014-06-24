component output=false extends="preside.system.base.Service" {

// CONSTRUCTOR
	public any function init( required array autoDiscoverDirectories ) output=false {
		super.init( argumentCollection=arguments );
		_setAutoDiscoverDirectories( arguments.autoDiscoverDirectories );
		reload();

		return this;
	}

// PUBLIC API METHODS
	public any function saveConfig( required string category, required string setting, required string value ) output=false  {
		var poService = _getPresideObjectService();

		transaction {
			var currentRecord = poService.selectData(
				  objectName   = "system_config"
				, selectFields = [ "id" ]
				, filter       = { category = arguments.category, label = arguments.setting }
			);

			if ( currentRecord.recordCount ) {
				return poService.updateData(
					  objectName = "system_config"
					, data       = { value = arguments.value }
					, id         = currentRecord.id
				);
			} else {
				return poService.insertData(
					  objectName = "system_config"
					, data       = { category = arguments.category, label = arguments.setting, value = arguments.value }
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
		var objectsPath             = "/i18n/system-config";
		var ids                     = {};
		var autoDiscoverDirectories = _getAutoDiscoverDirectories();

		for( var dir in autoDiscoverDirectories ) {
			dir   = ReReplace( dir, "/$", "" );
			var objects = DirectoryList( dir & objectsPath, false, "query", "*.properties" );

			for ( var obj in objects ) {
				if ( obj.type eq "File" ) {
					ids[ ReReplace( obj.name, "\.properties$", "" ) ] = true;
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

	private struct function _getConfigCategories() output=false {
		return _configCategories;
	}
	private void function _setConfigCategories( required struct configCategories ) output=false {
		_configCategories = arguments.configCategories;
	}

}