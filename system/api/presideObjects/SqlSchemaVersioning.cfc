component output=false singleton=true {

// CONSTRUCTOR
	/**
	 * @adapterFactory.inject AdapterFactory
	 * @sqlRunner.inject      SqlRunner
	 * @dbInfoService.inject  DbInfoService
	 */
	public any function init( required any adapterFactory, required any sqlRunner, required any dbInfoService ) output=false {
		_setAdapterFactory( arguments.adapterFactory );
		_setSqlRunner( arguments.sqlRunner );
		_setDbInfoService( arguments.dbInfoService );

		return this;
	}

// PUBLIC API METHODS
	public struct function getVersions( required array dsns ) output=false {
		var dsn            = "";
		var versions       = {};
		var versionRecords = "";
		var versionRecord  = "";

		for( dsn in dsns ){
			_checkVersionsTableExistance( dsn = dsn );
			versionRecords = _runSql(
				  sql = "select entity_type, entity_name, parent_entity_name, version_hash from _preside_generated_entity_versions order by entity_type, parent_entity_name"
				, dsn = dsn
			);

			for( versionRecord in versionRecords ) {
				if ( not StructKeyExists( versions, versionRecord.entity_type ) ) {
					versions[ versionRecord.entity_type ] = {};
				}

				if ( not IsNull( versionRecord.parent_entity_name ) ) {
					if ( not StructKeyExists( versions[ versionRecord.entity_type ], versionRecord.parent_entity_name ) ) {
						versions[ versionRecord.entity_type ][ versionRecord.parent_entity_name ] = {};
					}
					versions[ versionRecord.entity_type ][ versionRecord.parent_entity_name ][ versionRecord.entity_name ] = versionRecord.version_hash;
				} else {
					versions[ versionRecord.entity_type ][ versionRecord.entity_name ] = versionRecord.version_hash;
				}

			}
		}

		return versions;
	}

	public void function setVersion(
		  required string dsn
		, required string entityType
		, required string entityName
		, required string version
		,          string parentEntity

	) output=false {
		var deleteSql    = "delete from _preside_generated_entity_versions where entity_type = ? and entity_name = ? and parent_entity_name ";
		var insertSql    = "insert into _preside_generated_entity_versions( entity_type, entity_name, version_hash, date_modified";
		var ts           = DateFormat( Now(), "yyyy-mm-dd " ) & TimeFormat( Now(), "HH:mm:ss" );
		var deleteParams = [
			  { value=arguments.entityType, type="cf_sql_varchar" }
			, { value=arguments.entityName, type="cf_sql_varchar" }
		];
		var insertParams = [
			  { value=arguments.entityType, type="cf_sql_varchar" }
			, { value=arguments.entityName, type="cf_sql_varchar" }
			, { value=arguments.version   , type="cf_sql_varchar" }
			, { value=ts                  , type="cf_sql_ddatetime" }
		];

		if ( StructKeyExists( arguments, "parentEntity" ) ) {
			deleteSql &= "= ?";
			insertSql &= ", parent_entity_name ) values ( ?, ?, ?, ?, ? )";
			ArrayAppend( deleteParams, { value=arguments.parentEntity, type="cf_sql_varchar" } );
			ArrayAppend( insertParams, { value=arguments.parentEntity, type="cf_sql_varchar" } );
		} else {
			deleteSql &= "is null";
			insertSql &= " ) values ( ?, ?, ?, ? )";
		}

		_runSql( sql=deleteSql, dsn=arguments.dsn, params=deleteParams );
		_runSql( sql=insertSql, dsn=arguments.dsn, params=insertParams );
	}

// PRIVATE HELPERS
	private void function _checkVersionsTableExistance( required string dsn ) output=false {
		var versionTable  = "_preside_generated_entity_versions";
		var existingTable = _getTableInfo(
			  tableName = versionTable
			, dsn       = arguments.dsn
		);

		if ( not existingTable.recordCount ) {
			_createVersionTable( arguments.dsn );
		}
	}

	private void function _createVersionTable( required string dsn ) output=false {
		var adapter = _getAdapter( arguments.dsn );
		var columnDefs = "";
		var tableSql = "";
		var indexSql = "";

		columnDefs = adapter.getColumnDefinitionSql(
			  columnName = "entity_type"
			, dbType     = "varchar"
			, maxLength  = "10"
			, nullable   = false
		);
		columnDefs = ListAppend( columnDefs, adapter.getColumnDefinitionSql(
			  columnName = "entity_name"
			, dbType     = "varchar"
			, maxLength  = "200"
			, nullable   = false
		) );
		columnDefs = ListAppend( columnDefs, adapter.getColumnDefinitionSql(
			  columnName = "parent_entity_name"
			, dbType     = "varchar"
			, maxLength  = "200"
			, nullable   = true
		) );
		columnDefs = ListAppend( columnDefs, adapter.getColumnDefinitionSql(
			  columnName = "version_hash"
			, dbType     = "varchar"
			, maxLength  = "32"
			, nullable   = false
		) );
		columnDefs = ListAppend( columnDefs, adapter.getColumnDefinitionSql(
			  columnName = "date_modified"
			, dbType     = "timestamp"
			, nullable   = false
		) );

		tableSql = adapter.getTableDefinitionSql(
			  tableName = "_preside_generated_entity_versions"
			, columnSql = columnDefs
		);

		indexSql = adapter.getIndexSql(
			  indexName = "ux_preside_generated_entity_versions"
			, tableName = "_preside_generated_entity_versions"
			, fieldList = "entity_type,parent_entity_name,entity_name"
			, unique    = true
		);

		_runSql( sql=tableSql, dsn=arguments.dsn );
	}

	private any function _getAdapter() output=false {
		return _getAdapterFactory().getAdapter( argumentCollection = arguments );
	}

	private any function _runSql() output=false {
		return _getSqlRunner().runSql( argumentCollection = arguments );
	}

	private query function _getTableInfo() output=false {
		return _getDbInfoService().getTableInfo( argumentCollection = arguments );
	}


// GETTERS AND SETTERS
	private any function _getAdapterFactory() output=false {
		return _adapterFactory;
	}
	private void function _setAdapterFactory( required any adapterFactory ) output=false {
		_adapterFactory = arguments.adapterFactory;
	}

	private any function _getSqlRunner() output=false {
		return _sqlRunner;
	}
	private void function _setSqlRunner( required any sqlRunner ) output=false {
		_sqlRunner = arguments.sqlRunner;
	}

	private any function _getDbInfoService() output=false {
		return _dbInfoService;
	}
	private void function _setDbInfoService( required any dbInfoService ) output=false {
		_dbInfoService = arguments.dbInfoService;
	}
}