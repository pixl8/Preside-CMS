component output=false singleton=true {

// CONSTRUCTOR

	/**
	 * @dbInfoService.inject  DbInfoService
	 * @cache.inject          cachebox:SystemCache
	 */
	public any function init( required any dbInfoService, required any cache ) output=false {
		_setCache( arguments.cache );
		_setDbInfoService( arguments.dbInfoService );

		return this;
	}

// PUBLIC API METHODS
	public any function getAdapter( required string dsn ) output=false {
		var cache    = _getCache();
		var cacheKey = "DBAdaptor for " & arguments.dsn;
		var adapter  = cache.get( cacheKey );
		var dbType   = "";

		if ( not IsNull( adapter ) ) {
			return adapter;
		}

		dbType = _getDbType( dsn = arguments.dsn );
		switch( dbType ) {
			case "MySql":
				adapter = new MySqlAdapter();
			break;

			default:
				throw( type="PresideObjects.databaseEngineNotSupported", message="The database engine, [#dbType#], is not supported by the PresideObjects engine at this time" );
		}

		cache.set( cacheKey, adapter );

		return adapter;
	}

// PRIVATE HELPERS
	private string function _getDbType( required string dsn ) output=false {
		var db = QueryNew('');

		try {
			db = _getDbInfoService().getDatabaseVersion( arguments.dsn );

		} catch ( any e ) {}

		if ( not db.recordCount ) {
			throw( type="PresideObjects.datasourceNotFound", message="Datasource, [#arguments.dsn#], not found." );
		}

		return db.database_productname;
	}

// GETTERS AND SETTERS
	private any function _getDbInfoService() output=false {
		return _dbInfoService;
	}
	private void function _setDbInfoService( required any dbInfoService ) output=false {
		_dbInfoService = arguments.dbInfoService;
	}

	private any function _getCache() output=false {
		return _cache;
	}
	private void function _setCache( required any cache ) output=false {
		_cache = arguments.cache;
	}

}