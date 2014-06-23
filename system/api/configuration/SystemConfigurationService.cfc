component output=false extends="preside.system.base.Service" {

// CONSTRUCTOR
	public any function init( required array autoDiscoverDirectories ) output=false {
		_setAutoDiscoverDirectories( arguments.autoDiscoverDirectories );
		reload();

		return this;
	}

// PUBLIC API METHODS
	public array function listConfigCategories() output=false {
		var categories = _getConfigCategories();
		var result    = [];

		for( var id in categories ){
			ArrayAppend( result, categories[ id ] );
		}

		return result;
	}

	public void function reload() output=false {
		_setConfigCategories({});
		_autoDiscoverCategories();
	}

// PRIVATE HELPERS
	private void function _autoDiscoverCategories() output=false {
		var objectsPath             = "/preside-objects/system-config";
		var ids                     = {};
		var autoDiscoverDirectories = _getAutoDiscoverDirectories();

		for( var dir in autoDiscoverDirectories ) {
			dir   = ReReplace( dir, "/$", "" );
			var objects = DirectoryList( dir & objectsPath, false, "query", "*.cfc" );

			for ( var obj in objects ) {
				if ( obj.type eq "File" ) {
					ids[ ReReplace( obj.name, "\.cfc$", "" ) ] = true;
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
			, presideObject    = _getConventionsBaseCategoryPresideObject( arguments.id )
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
	private string function _getConventionsBaseCategoryPresideObject( required string id ) output=false {
		return arguments.id;
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