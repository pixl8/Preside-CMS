component output=false singleton=true {

// CONSTRUCTOR

	/**
	 * @dbInfoService.inject  DbInfoService
	 */
	public any function init( required any dbInfoService ) output=false {
		_setDbInfoService( arguments.dbInfoService );
		_setAdapters( {} )

		return this;
	}

// PUBLIC API METHODS
	public any function getAdapter( required string dsn ) output=false {
		var adapters = _getAdapters();

		if ( !adapters.keyExists( arguments.dsn ) ) {
			dbType = _getDbType( dsn = arguments.dsn );

			switch( dbType ) {
				case "MySql":
					adapters[ arguments.dsn ] = new MySqlAdapter();
				break;

				default:
					throw( type="PresideObjects.databaseEngineNotSupported", message="The database engine, [#dbType#], is not supported by the PresideObjects engine at this time" );
			}
		}

		return adapters[ arguments.dsn ];
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

	private any function _getAdapters() output=false {
		return _adapters;
	}
	private void function _setAdapters( required any adapters ) output=false {
		_adapters = arguments.adapters;
	}

}