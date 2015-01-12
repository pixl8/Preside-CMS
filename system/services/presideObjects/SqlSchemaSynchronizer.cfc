component output=false singleton=true {

// CONSTRUCTOR
	/**
	 * @adapterFactory.inject          AdapterFactory
	 * @sqlRunner.inject               SqlRunner
	 * @dbInfoService.inject           DbInfoService
	 * @schemaVersioningService.inject SqlSchemaVersioning
	 * @autoRunScripts.inject          coldbox:setting:autoSyncDb
	 */
	public any function init(
		  required any     adapterFactory
		, required any     sqlRunner
		, required any     dbInfoService
		, required any     schemaVersioningService
		, required boolean autoRunScripts

	) output=false {

		_setAdapterFactory( arguments.adapterFactory );
		_setSqlRunner( arguments.sqlRunner );
		_setDbInfoService( arguments.dbInfoService );
		_setSchemaVersioningService( arguments.schemaVersioningService );
		_setAutoRunScripts( arguments.autoRunScripts );

		return this;
	}

// PUBLIC API METHODS
	public void function synchronize( required array dsns, required struct objects ) output=false {
		var versions           = _getVersionsOfDatabaseObjects( arguments.dsns );
		var objName            = "";
		var obj                = "";
		var table              = "";
		var dbVersion          = "";
		var tableExists        = "";
		var tableVersionExists = "";

		_ensureValidDbEntityNames( arguments.objects );

		for( objName in objects ) {
			obj       = objects[ objName ];
			obj.sql   = _generateTableAndColumnSql( argumentCollection = obj.meta );
			dbVersion &= obj.sql.table.version;
		}
		dbVersion = Hash( dbVersion );
		if ( ( versions.db.db ?: "" ) neq dbVersion ) {
			for( objName in objects ) {
				obj                = objects[ objName ];
				tableVersionExists = StructKeyExists( versions, "table" ) and StructKeyExists( versions.table, obj.meta.tableName );
				tableExists        = tableVersionExists or _getTableInfo( tableName=obj.meta.tableName, dsn=obj.meta.dsn ).recordCount;

				if ( not tableExists ) {
					try {
						_createObjectInDb(
							  generatedSql = obj.sql
							, dsn          = obj.meta.dsn
							, tableName    = obj.meta.tableName
						);
					} catch( any e ) {
						throw(
							  type    = "presideobjectservice.dbsync.error"
							, message = "An error occurred while attempting to create a table for the [#objName#] object."
							, detail  = "SQL: [#( e.sql ?: '' )#]. Error message: [#e.message#]. Error Detail [#e.detail#]."
						);
					}
				} elseif ( not tableVersionExists or versions.table[ obj.meta.tableName ] neq obj.sql.table.version ) {
					try {
						_enableFkChecks( false, obj.meta.dsn );
						_updateDbTable(
							  tableName      = obj.meta.tableName
							, generatedSql   = obj.sql
							, dsn            = obj.meta.dsn
							, indexes        = obj.meta.indexes
							, columnVersions = IsDefined( "versions.column.#obj.meta.tableName#" ) ? versions.column[ obj.meta.tableName ] : {}
						);
						_enableFkChecks( true, obj.meta.dsn );
					} catch( any e ) {
						throw(
							  type    = "presideobjectservice.dbsync.error"
							, message = "An error occurred while attempting to alter a table for the [#objName#] object. If the issue relates to foreign keys or indexes, manually deleting the foreign keys from the database will often resolve the issue."
							, detail  = "SQL: [#( e.sql ?: '' )#]. Error message: [#e.message#]. Error Detail [#e.detail#]."
						);
					}
				}
			}
			_syncForeignKeys( objects );

			for( dsn in dsns ){
				_setDatabaseObjectVersion(
					  entityType = "db"
					, entityName = "db"
					, version    = dbVersion
					, dsn        = dsn
				);
			}
		}

		if ( !_getAutoRunScripts() ) {
			var scriptsToRun = _getBuiltSqlScriptArray();
			var versionScriptsToRun = _getVersionTableScriptArray();
			if ( scriptsToRun.len() || versionScriptsToRun.len() ) {
				var newLine = Chr( 10 );
				var sql = "/**
 * The following commands are to make alterations to the database schema
 * in order to synchronize it with the PresideCMS codebase.
 *
 * Generated on: #Now()#
 *
 * Please review the scripts before running.
 */" & newline & newline;
				for( var script in scriptsToRun ) {
					sql &= script.sql & ";" & newline;
				}
				sql &= newline & "/* The commands below ensure that PresideCMS's internal DB versioning tracking is up to date */" & newline & newline;
				for( var script in versionScriptsToRun ) {
					sql &= script.sql & ";" & newline;
				}

				throw(
					  type    = "presidecms.auto.schema.sync.disabled"
					, message = "Code changes have been detected that require a database changes. However, auto db sync is disabled for this website. Please see the error detail for full SQL script that should be run directly on your database."
					, detail  = sql
				);
			}
		}
	}

// PRIVATE HELPERS
	private struct function _generateTableAndColumnSql(
		  required string dsn
		, required string tableName
		, required struct properties
		, required struct indexes
		, required string dbFieldList
		,          struct relationships = {}

	) output=false {
		var adapter   = _getAdapter( dsn = arguments.dsn );
		var columnSql = "";
		var colName   = "";
		var column    = "";
		var delim     = "";
		var args      = "";
		var colMeta   = "";
		var indexName = "";
		var index     = "";
		var fkName    = "";
		var fk        = "";
		var sql       = {
			  columns = {}
			, indexes = {}
			, table   = { version="", sql="" }
		};

		for( colName in ListToArray( arguments.dbFieldList ) ){
			column = sql.columns[ colName ] = StructNew();
			colMeta = arguments.properties[ colName ];
			args = {
				  tableName     = arguments.tableName
				, columnName    = colName
				, dbType        = colMeta.dbType
				, nullable      = not IsBoolean( colMeta.required ) or not colMeta.required
				, primaryKey    = IsBoolean( colMeta.pk ?: "" ) && colMeta.pk
				, autoIncrement = colMeta.generator eq "increment"
				, maxLength     = colMeta.maxLength
			};

			column.definitionSql = adapter.getColumnDefinitionSql( argumentCollection = args );
			column.alterSql      = adapter.getAlterColumnSql( argumentCollection = args );
			column.addSql        = adapter.getAddColumnSql( argumentCollection = args );
			column.version       = Hash( column.definitionSql );

			columnSql &= delim & column.definitionSql;
			delim = ", ";
		}


		for( indexName in arguments.indexes ){
			index = arguments.indexes[ indexName ];
			sql.indexes[ indexName ] = {
				createSql = adapter.getIndexSql(
					  indexName = indexName
					, tableName = arguments.tableName
					, fieldList = index.fields
					, unique    = index.unique
				),
				dropSql = adapter.getDropIndexSql(
					  indexName = indexName
					, tableName = arguments.tableName
				)
			};
		}

		for( fkName in arguments.relationships ){
			fk = arguments.relationships[ fkName ];

			sql.relationships[ fkName ] = {
				createSql = adapter.getForeignKeyConstraintSql(
					  sourceTable    = fk.fk_table
					, sourceColumn   = fk.fk_column
					, constraintName = fkName
					, foreignTable   = fk.pk_table
					, foreignColumn  = fk.pk_column
					, onDelete       = fk.on_delete
					, onUpdate       = fk.on_update
				)
			};

		}

		sql.table.sql = adapter.getTableDefinitionSql(
			  tableName = arguments.tableName
			, columnSql = columnSql
		);
		sql.table.version = Hash( sql.table.sql & SerializeJson( arguments.indexes ) & SerializeJson( arguments.relationships ) );

		return sql;
	}

	private void function _createObjectInDb( required struct generatedSql, required string dsn ) output=false {
		var columnName = "";
		var column     = "";
		var indexName  = "";
		var index      = "";
		var table      = arguments.generatedSql.table;

		_runSql( sql=table.sql, dsn=arguments.dsn );
		_setDatabaseObjectVersion(
			  entityType = "table"
			, entityName = arguments.tableName
			, version    = table.version
			, dsn        = arguments.dsn
		);

		for( columnName in arguments.generatedSql.columns ){
			column = arguments.generatedSql.columns[ columnName ];
			_setDatabaseObjectVersion(
				  entityType   = "column"
				, parentEntity = arguments.tableName
				, dsn          = arguments.dsn
				, entityName   = columnName
				, version      = column.version
			);
		}

		for( indexName in arguments.generatedSql.indexes ) {
			index = arguments.generatedSql.indexes[ indexName ];
			_runSql( sql=index.createSql, dsn=arguments.dsn );
		}
	}

	private void function _updateDbTable(
		  required string tableName
		, required struct generatedSql
		, required struct indexes
		, required string dsn
		, required struct columnVersions

	) output=false {
		var columnsFromDb = _getTableColumns( tableName=arguments.tableName, dsn=arguments.dsn );
		var indexesFromDb = _getTableIndexes( tableName=arguments.tableName, dsn=arguments.dsn );
		var dbColumnNames = ValueList( columnsFromDb.column_name );
		var colsSql       = arguments.generatedSql.columns;
		var indexesSql    = arguments.generatedSql.indexes;
		var adapter       = _getAdapter( arguments.dsn );
		var column        = "";
		var colSql        = "";
		var index         = "";
		var indexSql      = "";
		var deprecateSql  = "";

		for( column in columnsFromDb ){
			if ( not column.column_name contains "__deprecated__" ) {
				if ( StructKeyExists( colsSql, column.column_name ) ) {
					colSql = colsSql[ column.column_name ];

					if ( not StructKeyExists( columnVersions, column.column_name ) or colSql.version neq columnVersions[ column.column_name ] ) {
						if ( column.is_foreignkey ){
							_deleteForeignKeysForColumn( primaryTableName=column.referenced_primarykey_table, foreignTableName=arguments.tableName, foreignColumnName=column.column_name, dsn=arguments.dsn );
						}
						_runSql( sql=colSql.alterSql, dsn=arguments.dsn );
						_setDatabaseObjectVersion(
							  entityType   = "column"
							, parentEntity = arguments.tableName
							, entityName   = column.column_name
							, version      = colSql.version
							, dsn          = arguments.dsn
						);
					}
				} else {
					deprecateSql = adapter.getAlterColumnSql(
						  tableName     = arguments.tableName
						, columnName    = column.column_name
						, newName       = "__deprecated__" & column.column_name
						, dbType        = column.type_name
						, nullable      = true // its deprecated, must be nullable!
						, maxLength     = adapter.doesColumnTypeRequireLengthSpecification( column.type_name ) ? ( Val( IsNull( column.column_size ) ? 0 : column.column_size ) ) : 0
						, primaryKey    = column.is_primarykey
						, autoIncrement = column.is_autoincrement
					);

					if ( column.is_foreignkey ){
						_deleteForeignKeysForColumn( primaryTableName=column.referenced_primarykey_table, foreignTableName=arguments.tableName, foreignColumnName=column.column_name, dsn=arguments.dsn );
					}
					_runSql( sql=deprecateSql, dsn=arguments.dsn );
					_setDatabaseObjectVersion(
						  entityType   = "column"
						, parentEntity = arguments.tableName
						, entityName   = column.column_name
						, version      = "DEPRECATED"
						, dsn          = arguments.dsn
					);
				}
			}
		}

		for( column in colsSql ) {
			if ( not ListFindNoCase( dbColumnNames, column ) ) {
				colSql = colsSql[ column ];
				_runSql( sql=colSql.addSql, dsn=arguments.dsn );
				_setDatabaseObjectVersion(
					  entityType   = "column"
					, parentEntity = arguments.tableName
					, entityName   = column
					, version      = colSql.version
					, dsn          = arguments.dsn
				);
			}
		}

		for( index in indexesFromDb ){
			if ( StructKeyExists( arguments.indexes, index ) and SerializeJson( arguments.indexes[index] ) NEQ SerializeJson( indexesFromDb[index] ) ){
				indexSql = indexesSql[ index ];
				_runSql( sql=indexSql.dropSql  , dsn=arguments.dsn );
				_runSql( sql=indexSql.createSql, dsn=arguments.dsn );
			}
		}
		for( index in indexesSql ){
			if ( not StructKeyExists( indexesFromDb, index ) ) {
				_runSql( sql=indexesSql[index].createSql, dsn=arguments.dsn );
			}
		}

		_setDatabaseObjectVersion(
			  entityType = "table"
			, entityName = arguments.tableName
			, version    = arguments.generatedSql.table.version
			, dsn        = arguments.dsn
		);
	}

	private void function _deleteForeignKeysForColumn(
		  required string primaryTableName
		, required string foreignTableName
		, required string foreignColumnName
		, required string dsn

	) output=false {
		var keys    = "";
		var keyName = "";
		var key     = "";
		var adapter = _getAdapter( dsn );
		var dropSql = "";

		keys = _getTableForeignKeys( tableName = arguments.primaryTableName, dsn = arguments.dsn );

		for( keyName in keys ){
			key = keys[ keyName ];
			if ( key.fk_table eq arguments.foreignTableName and key.fk_column eq arguments.foreignColumnName ) {
				sql = adapter.getDropForeignKeySql( tableName = key.fk_table, foreignKeyName = keyName );

				_runSql( sql = sql, dsn = arguments.dsn );
			}
		}
	}

	private void function _syncForeignKeys( required struct objects ) output=false {
		var objName         = "";
		var obj             = "";
		var dbKeys          = "";
		var dbKeyName       = "";
		var dbKey           = "";
		var key             = "";
		var foreignObjName  = "";
		var foreignObj      = "";
		var shouldBeDeleted = false;
		var oldKey          = "";
		var newKey          = "";
		var deleteSql       = "";
		var existingKeysNotToTouch = {};

		for( objName in objects ) {
			obj = objects[ objName ];
			dbKeys = _getTableForeignKeys( tableName = obj.meta.tableName, dsn = obj.meta.dsn );

			param name="obj.meta.relationships" default=StructNew();
			param name="obj.sql.relationships"  default=StructNew();

			for( dbKeyName in dbKeys ){
				dbKey = dbKeys[ dbKeyName ];

				shouldBeDeleted = true;
				for( foreignObjName in objects ){
					foreignObj = objects[ foreignObjName ];
					if ( foreignObj.meta.tableName eq dbKey.fk_table ) {
						param name="foreignObj.meta.relationships" default=StructNew();

						if ( StructKeyExists( foreignObj.meta.relationships, dbKeyName ) ){

							oldKey = SerializeJson( dbKey );
							newKey = SerializeJson( foreignObj.meta.relationships[ dbKeyName ] );

							shouldBeDeleted = oldKey != newKey;
							if ( !shouldBeDeleted ) {
								existingKeysNotToTouch[ foreignObjName ] = ListAppend( existingKeysNotToTouch[ foreignObjName ] ?: "", dbKeyName );
							}
						}
						break;
					}
				}

				if ( shouldBeDeleted ) {
					deleteSql = _getAdapter( obj.meta.dsn ).getDropForeignKeySql(
						  foreignKeyName = dbKeyName
						, tableName      = dbKey.fk_table
					);
					try {
						_runSql( sql = deleteSql, dsn = obj.meta.dsn );
					} catch( any e ) {
						throw(
							  type    = "presideobjectservice.dbsync.error"
							, message = "An error occurred while attempting to delete a foreign key [#dbKeyName#] for the [#objName#] object."
							, detail  = "SQL: [#deleteSql#]. Error message: [#e.message#]. Error Detail [#e.detail#]."
						);
					}
				}
			}
		}
		for( objName in objects ) {
			obj = objects[ objName ];
			for( key in obj.sql.relationships ){
				if ( !ListFindNoCase( existingKeysNotToTouch[ objName ] ?: "", key ) ) {
					transaction {
						if ( _getAutoRunScripts() ) {
							// try and catch around a fk deletion, no native way to delete foreign key only if exists
							// we need to do this because apparently there's some circumstances which lead to the FK already existing
							// despite our checks above
							try {
								deleteSql = _getAdapter( obj.meta.dsn ).getDropForeignKeySql(
									  foreignKeyName = key
									, tableName      = obj.meta.tableName
								);
								_runSql( sql = deleteSql, dsn = obj.meta.dsn );
							} catch( any e ) {}
						}

						try {
							_runSql( sql = obj.sql.relationships[ key ].createSql, dsn = obj.meta.dsn );
						} catch( any e ) {
							throw(
								  type    = "presideobjectservice.dbsync.error"
								, message = "An error occurred while attempting to create a foreign key for the [#objName#] object."
								, detail  = "SQL: [#obj.sql.relationships[ key ].createSql#]. Error message: [#e.message#]. Error Detail [#e.detail#]."
							);
						}
					}
				}
			}
		}
	}

	private void function _enableFkChecks( required boolean enabled, required string dsn ) output=false {
		var adapter = _getAdapter( dsn=arguments.dsn );

		if ( adapter.canToggleForeignKeyChecks() ) {
			_runSql(
				  dsn = arguments.dsn
				, sql = adapter.getToggleForeignKeyChecks( checksEnabled=arguments.enabled )
			);
		}
	}

	private array function _getBuiltSqlScriptArray() output=false {
		request._sqlSchemaSynchronizerSqlArray = request._sqlSchemaSynchronizerSqlArray ?: [];

		return request._sqlSchemaSynchronizerSqlArray;
	}

	private array function _getVersionTableScriptArray() output=false {
		request._sqlSchemaSynchronizerVersionSqlArray = request._sqlSchemaSynchronizerVersionSqlArray ?: [];

		return request._sqlSchemaSynchronizerVersionSqlArray;
	}



// SIMPLE PRIVATE PROXIES
	private any function _getAdapter() output=false {
		return _getAdapterFactory().getAdapter( argumentCollection = arguments );
	}

	private any function _runSql() output=false {
		if ( _getAutoRunScripts() ) {
			return _getSqlRunner().runSql( argumentCollection = arguments );
		}

		var sqlScripts = _getBuiltSqlScriptArray();
		sqlScripts.append( Duplicate( arguments ) );
	}

	private query function _getTableInfo() output=false {
		return _getDbInfoService().getTableInfo( argumentCollection = arguments );
	}

	private query function _getTableColumns() output=false {
		return _getDbInfoService().getTableColumns( argumentCollection = arguments );
	}

	private struct function _getTableIndexes() output=false {
		return _getDbInfoService().getTableIndexes( argumentCollection = arguments );
	}

	private struct function _getTableForeignKeys() output=false {
		return _getDbInfoService().getTableForeignKeys( argumentCollection = arguments );
	}

	private struct function _getVersionsOfDatabaseObjects() output=false {
		return _getSchemaVersioningService().getVersions( argumentCollection = arguments );
	}

	private void function _setDatabaseObjectVersion() output=false {
		if ( _getAutoRunScripts() ) {
			return _getSchemaVersioningService().setVersion( argumentCollection = arguments );
		}

		var syncScripts    = _getVersionTableScriptArray();
		var versionScripts = _getSchemaVersioningService().getSetVersionPlainSql( argumentCollection=arguments );
		for( var script in versionScripts ){
			syncScripts.append( script );
		}
	}

	private void function _ensureValidDbEntityNames( required struct objects ) output=false {
		for( var objectName in arguments.objects ) {
			var objMeta = arguments.objects[ objectName ].meta ?: {};
			var adapter = _getAdapterFactory().getAdapter( objMeta.dsn ?: "" );
			var maxTableNameLength = adapter.getTableNameMaxLength();

			if ( Len( objMeta.tableName ?: "" ) > maxTableNameLength ) {
				objMeta.tableName = Left( objMeta.tableName, maxTableNameLength );
			}
		}
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

	private any function _getSchemaVersioningService() output=false {
		return _schemaVersioningService;
	}
	private void function _setSchemaVersioningService( required any schemaVersioningService ) output=false {
		_schemaVersioningService = arguments.schemaVersioningService;
	}

	private boolean function _getAutoRunScripts() output=false {
		return _autoRunScripts;
	}
	private void function _setAutoRunScripts( required boolean autoRunScripts ) output=false {
		_autoRunScripts = arguments.autoRunScripts;
	}
}