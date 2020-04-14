/**
 * @singleton
 *
 */
component {

// CONSTRUCTOR
	/**
	 * @adapterFactory.inject              AdapterFactory
	 * @sqlRunner.inject                   SqlRunner
	 * @dbInfoService.inject               DbInfoService
	 * @schemaVersioningService.inject     SqlSchemaVersioning
	 * @autoRunScripts.inject              coldbox:setting:autoSyncDb
	 * @autoRestoreDeprecatedFields.inject coldbox:setting:autoRestoreDeprecatedFields
	 */
	public any function init(
		  required any     adapterFactory
		, required any     sqlRunner
		, required any     dbInfoService
		, required any     schemaVersioningService
		, required boolean autoRunScripts
		, required boolean autoRestoreDeprecatedFields

	) {

		_setAdapterFactory( arguments.adapterFactory );
		_setSqlRunner( arguments.sqlRunner );
		_setDbInfoService( arguments.dbInfoService );
		_setSchemaVersioningService( arguments.schemaVersioningService );
		_setAutoRunScripts( arguments.autoRunScripts );
		_setAutoRestoreDeprecatedFields( arguments.autoRestoreDeprecatedFields );

		return this;
	}

// PUBLIC API METHODS
	public void function synchronize( required array dsns, required struct objects ) {
		var versions           = _getVersionsOfDatabaseObjects( arguments.dsns );
		var objName            = "";
		var obj                = "";
		var table              = "";
		var dbVersion          = [];
		var tableExists        = "";
		var tableVersionExists = "";

		for( objName in objects ) {
			obj       = objects[ objName ];
			obj.sql   = _generateTableAndColumnSql( argumentCollection = obj.meta );
			dbVersion.append( obj.sql.table.version );
		}
		dbVersion.sort( "text" );
		dbVersion = Hash( dbVersion.toList() );
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
				} else if ( not tableVersionExists or versions.table[ obj.meta.tableName ] neq obj.sql.table.version ) {
					try {
						_enableFkChecks( false, obj.meta.dsn, obj.meta.tableName );
						_updateDbTable(
							  tableName        = obj.meta.tableName
							, generatedSql     = obj.sql
							, dsn              = obj.meta.dsn
							, indexes          = obj.meta.indexes
							, columnVersions   = IsDefined( "versions.column.#obj.meta.tableName#" ) ? versions.column[ obj.meta.tableName ] : {}
							, objectProperties = obj.meta.properties
						);
						_enableFkChecks( true, obj.meta.dsn, obj.meta.tableName );
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

		for( objName in objects ) {
			objects[ objName ].delete( "sql" );
		}

		var cleanupScripts = _getSchemaVersioningService().cleanupDbVersionTableEntries( versions, objects, dsns[1], _getAutoRunScripts() );

		if ( !_getAutoRunScripts() ) {
			var scriptsToRun = _getBuiltSqlScriptArray();
			var scriptsOutput = [];
			var versionScriptsToRun = _getVersionTableScriptArray();
			if ( scriptsToRun.len() || versionScriptsToRun.len() || cleanupScripts.len() ) {
				var newLine = Chr( 10 );
				var sql = "/**
 * The following commands are to make alterations to the database schema
 * in order to synchronize it with the Preside codebase.
 *
 * Generated on: #Now()#
 *
 * Please review the scripts before running.
 */" & newline & newline;
				for( var script in scriptsToRun ) {
					if ( !scriptsOutput.findNoCase( script.sql ) ) {
						sql &= script.sql & ";" & newline;
						scriptsOutput.append( script.sql );
					}
				}
				sql &= newline & "/* The commands below ensure that Preside's internal DB versioning tracking is up to date */" & newline & newline;
				for( var script in versionScriptsToRun ) {
					sql &= script.sql & ";" & newline;
				}
				for( var script in cleanupScripts ) {
					sql &= script & ";" & newline;
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

	) {
		var adapter        = _getAdapter( dsn = arguments.dsn );
		var columnSql      = "";
		var colName        = "";
		var column         = "";
		var delim          = "";
		var args           = "";
		var colMeta        = "";
		var indexName      = "";
		var validIndexName = "";
		var index          = "";
		var fkName         = "";
		var fk             = "";
		var sql            = {
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
			index          = arguments.indexes[ indexName ];
			validIndexName = adapter.ensureValidIndexName( indexName );

			if ( indexName != validIndexName ) {
			    arguments.indexes[ validIndexName ] = index;
			    arguments.indexes.delete( indexName );
			    indexName = validIndexName;
			}

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

	private void function _createObjectInDb( required struct generatedSql, required string dsn ) {
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
		, required struct objectProperties

	) {
		var columnsFromDb   = _getTableColumns( tableName=arguments.tableName, dsn=arguments.dsn );
		var indexesFromDb   = _getTableIndexes( tableName=arguments.tableName, dsn=arguments.dsn );
		var dbColumnNames   = ValueList( columnsFromDb.column_name );
		var colsSql         = arguments.generatedSql.columns;
		var indexesSql      = arguments.generatedSql.indexes;
		var adapter         = _getAdapter( arguments.dsn );
		var column          = "";
		var colSql          = "";
		var index           = "";
		var indexSql        = "";
		var deprecateSql    = "";
		var renameSql       = "";
		var columnName      = "";
		var deDeprecateSql  = "";
		var wasDeDeprecated = false;
		var newName         = "";
		var colProperties   = {};

		for( column in columnsFromDb ){
			wasDeDeprecated = false;
			if ( _getAutoRestoreDeprecatedFields() || !column.column_name contains "__deprecated__" ) {
				columnName = Replace( column.column_name, "__deprecated__", "" );
				if ( StructKeyExists( colsSql, columnName ) ) {
					colSql = colsSql[ columnName ];

					if ( column.column_name contains "__deprecated__" ) {

						if ( !adapter.supportsRenameInAlterColumnStatement() ) {
							renameSql = adapter.getRenameColumnSql(
								  tableName     = arguments.tableName
								, oldColumnName = column.column_name
								, newColumnName = columnName
							);

							_runSql( sql=renameSql, dsn=arguments.dsn );
						}

						colProperties = objectProperties[ columnName ];

						deDeprecateSql = adapter.getAlterColumnSql(
							  tableName     = arguments.tableName
							, columnName    = column.column_name
							, newName       = columnName
							, dbType        = colProperties.dbType
							, nullable      = true // it was deprecated, must be nullable!
							, maxLength     = adapter.doesColumnTypeRequireLengthSpecification( column.type_name ) ? ( IsNumeric( colProperties.maxLength ?: "" ) ? colProperties.maxLength : 0 ) : 0
							, primaryKey    = IsBoolean( colProperties.pk ?: "" ) && colProperties.pk
							, autoIncrement = colProperties.generator eq "increment"
						);

						dbColumnNames   = Replace( dbColumnNames, column.column_name, columnName );
						wasDeDeprecated = true;

						_runSql( sql=deDeprecateSql, dsn=arguments.dsn );
					}

					if ( !wasDeDeprecated && ( !StructKeyExists( columnVersions, columnName ) || colSql.version != columnVersions[ columnName ] ) ) {

						for( index in indexesFromDb ){
							if ( StructKeyExists( arguments.indexes, index ) AND !findNoCase("id", column.column_name) AND listFindNoCase(indexesFromDb[index].fields, column.column_name) ) {
								indexSql = indexesSql[ index ];
								_runSql( sql=indexSql.dropSql  , dsn=arguments.dsn );
							}
						}

						if ( column.is_foreignkey ){
							_deleteForeignKeysForColumn(
								  primaryTableName  = column.referenced_primarykey_table
								, foreignTableName  = arguments.tableName
								, foreignColumnName = column.column_name
								, dsn               = arguments.dsn
							);
						}
						_runSql( sql=colSql.alterSql, dsn=arguments.dsn );
						_setDatabaseObjectVersion(
							  entityType   = "column"
							, parentEntity = arguments.tableName
							, entityName   = columnName
							, version      = colSql.version
							, dsn          = arguments.dsn
						);

						for( index in indexesFromDb ){
							if ( StructKeyExists( arguments.indexes, index ) AND !findNoCase("id", column.column_name) AND listFindNoCase(indexesFromDb[index].fields, column.column_name) ) {
								indexSql = indexesSql[ index ];
								_runSql( sql=indexSql.createSql, dsn=arguments.dsn );
							}
						}
					}
				} else if ( !column.column_name contains "__deprecated__" ) {
					newName = "__deprecated__" & column.column_name;
					if ( !adapter.supportsRenameInAlterColumnStatement() ) {
						renameSql = adapter.getRenameColumnSql(
							  tableName     = arguments.tableName
							, oldColumnName = column.column_name
							, newColumnName = newName
						);
						_runSql( sql=renameSql, dsn=arguments.dsn );

						deprecateSql = adapter.getAlterColumnSql(
							  tableName     = arguments.tableName
							, columnName    = newName
							, dbType        = column.type_name
							, nullable      = true // its deprecated, must be nullable!
							, maxLength     = adapter.doesColumnTypeRequireLengthSpecification( column.type_name ) ? ( Val( IsNull( column.column_size ) ? 0 : column.column_size ) ) : 0
							, primaryKey    = column.is_primarykey
							, autoIncrement = column.is_autoincrement
						);
						_runSql( sql=deprecateSql, dsn=arguments.dsn );
					} else {
						deprecateSql = adapter.getAlterColumnSql(
							  tableName     = arguments.tableName
							, columnName    = column.column_name
							, newName       = newName
							, dbType        = column.type_name
							, nullable      = true // its deprecated, must be nullable!
							, maxLength     = adapter.doesColumnTypeRequireLengthSpecification( column.type_name ) ? ( Val( IsNull( column.column_size ) ? 0 : column.column_size ) ) : 0
							, primaryKey    = column.is_primarykey
							, autoIncrement = column.is_autoincrement
						);
						_runSql( sql=deprecateSql, dsn=arguments.dsn );
					}
				}
			}
		}


		for( column in colsSql ) {
			if ( !ListFindNoCase( dbColumnNames, column ) ) {
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
			} else if ( !StructKeyExists( arguments.indexes, index ) && ReFindNoCase( '^[iu]x_', index ) ) {
				_runSql(
					  sql = adapter.getDropIndexSql( indexName=index, tableName=arguments.tableName )
					, dsn = arguments.dsn
				);
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

	) {
		var keys    = "";
		var keyName = "";
		var key     = "";
		var adapter = _getAdapter( dsn );
		var dropSql = "";

		keys = _getAllForeignKeys( dsn=arguments.dsn, cached=true );
		keys = keys[ foreignTableName ] ?: {};

		for( keyName in keys ){
			key = keys[ keyName ];
			if ( key.fk_table eq arguments.foreignTableName and key.fk_column eq arguments.foreignColumnName ) {
				sql = adapter.getDropForeignKeySql( tableName = key.fk_table, foreignKeyName = keyName );

				_runSql( sql = sql, dsn = arguments.dsn );
			}
		}
	}

	private void function _syncForeignKeys( required struct objects ) {
		var objName                = "";
		var obj                    = "";
		var dbKeys                 = "";
		var dbKeyName              = "";
		var dbKey                  = "";
		var key                    = "";
		var foreignObjName         = "";
		var foreignObj             = "";
		var shouldBeDeleted        = false;
		var deleteSql              = "";
		var adapter                = "";
		var onDelete               = "";
		var onUpdate               = "";
		var cascadingSupported     = "";
		var relationship           = "";
		var dsnKeys                = {};

		for( objName in objects ) {
			obj = objects[ objName ];
			adapter = _getAdapter( obj.meta.dsn );
			dsnKeys[ obj.meta.dsn ] = dsnKeys[ obj.meta.dsn ] ?: _getAllForeignKeys( dsn=obj.meta.dsn );

			dbKeys = dsnKeys[ obj.meta.dsn ][ obj.meta.tableName ] ?: {};

			param name="obj.meta.relationships" default=StructNew();
			param name="obj.sql.relationships"  default=StructNew();

			for( dbKeyName in dbKeys ){
				dbKey = dbKeys[ dbKeyName ];

				shouldBeDeleted = !StructKeyExists( obj.meta.relationships, dbKeyName ) && ReFindNoCase( "^fk_[0-9a-f]{32}$", dbKeyName );
				if ( shouldBeDeleted ) {
					deleteSql = adapter.getDropForeignKeySql(
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
			dsnKeys[ obj.meta.dsn ] = dsnKeys[ obj.meta.dsn ] ?: _getAllForeignKeys( dsn=obj.meta.dsn );
			dbKeys = dsnKeys[ obj.meta.dsn ][ obj.meta.tableName ] ?: {};

			for( key in obj.sql.relationships ){
				if ( !StructKeyExists( dbKeys, key ) ) {
					transaction {
						try {
							_runSql( sql = obj.sql.relationships[ key ].createSql, dsn = obj.meta.dsn );
						} catch( any e ) {
							var message = "An error occurred while attempting to create a foreign key for the [#objName#] object.";

							if ( ( e.detail ?: "" ) contains "Cannot add or update a child row: a foreign key constraint fails" ) {
								message &= " This error has been caused by existing data in the table not matching the foreign key requirements, or the foreign key field being newly added and not nullable. To fix, ensure that the foreign key column contains valid data and then reload the application once more.";
							}

							if ( ( e.detail ?: "" ) contains "errno: 150" ) {
								message &= " This may be due to a table or column collation mismatch. To fix, ensure that the tables and columns on either side of the relationship have the same collation setting.";
							}

							throw(
								  type    = "presideobjectservice.dbsync.error"
								, message = message
								, detail  = "SQL: [#obj.sql.relationships[ key ].createSql#]. Error message: [#e.message#]. Error Detail [#e.detail#]."
							);
						}
					}
				}
			}
		}
	}

	private void function _enableFkChecks( required boolean enabled, required string dsn, required string tableName ) {
		var adapter = _getAdapter( dsn=arguments.dsn );
		if ( adapter.canToggleForeignKeyChecks() ) {
			_runSql(
				  dsn = arguments.dsn
				, sql = adapter.getToggleForeignKeyChecks( checksEnabled=arguments.enabled, tableName=arguments.tableName )
			);
		}
	}

	private array function _getBuiltSqlScriptArray() {
		request._sqlSchemaSynchronizerSqlArray = request._sqlSchemaSynchronizerSqlArray ?: [];

		return request._sqlSchemaSynchronizerSqlArray;
	}

	private array function _getVersionTableScriptArray() {
		request._sqlSchemaSynchronizerVersionSqlArray = request._sqlSchemaSynchronizerVersionSqlArray ?: [];

		return request._sqlSchemaSynchronizerVersionSqlArray;
	}



// SIMPLE PRIVATE PROXIES
	private any function _getAdapter() {
		return _getAdapterFactory().getAdapter( argumentCollection = arguments );
	}

	private any function _runSql() {
		if ( _getAutoRunScripts() ) {
			return _getSqlRunner().runSql( argumentCollection = arguments );
		}

		var sqlScripts = _getBuiltSqlScriptArray();
		sqlScripts.append( Duplicate( arguments ) );
	}

	private query function _getTableInfo() {
		return _getDbInfoService().getTableInfo( argumentCollection = arguments );
	}

	private query function _getTableColumns() {
		try {
			return _getDbInfoService().getTableColumns( argumentCollection = arguments );
		} catch( any e ) {
			if ( e.message contains "there is no table that match the following pattern" ) {
				return QueryNew('');
			}

			rethrow;
		}
	}

	private struct function _getTableIndexes() {
		try {
			return _getDbInfoService().getTableIndexes( argumentCollection = arguments );
		} catch( any e ) {
			if ( e.message contains "there is no table that match the following pattern" ) {
				return {};
			}

			rethrow;
		}
	}

	private struct function _getAllForeignKeys( required string dsn, boolean cached=false ) {
		if ( arguments.cached && StructKeyExists( request, "_allForeignKeys.#arguments.dsn#" ) ) {
			return request[ "_allForeignKeys.#arguments.dsn#" ];
		}

		var adapter = _getAdapter( arguments.dsn );
		var db      = _getSqlRunner().runSql( sql=adapter.getDatabaseNameSql(), dsn=arguments.dsn ).db ?: "";
		var keys    = _getSqlRunner().runSql(
			  sql    = adapter.getAllForeignKeysSql()
			, dsn    = arguments.dsn
			, params = [ { name="databasename", type="cf_sql_varchar", value=db } ]
		);

		var constraints = {};
		for( var key in keys ){
			constraints[ key.table_name ] = constraints[ key.table_name ] ?: {};
			constraints[ key.table_name ][ key.constraint_name ] = {
				  pk_table  = key.referenced_table_name
				, fk_table  = key.table_name
				, pk_column = key.referenced_column_name
				, fk_column = key.column_name
			}
		}

		request[ "_allForeignKeys.#arguments.dsn#" ] = constraints;

		return constraints;
	}

	private struct function _getVersionsOfDatabaseObjects() {
		return _getSchemaVersioningService().getVersions( argumentCollection = arguments );
	}

	private void function _setDatabaseObjectVersion() {
		if ( _getAutoRunScripts() ) {
			return _getSchemaVersioningService().setVersion( argumentCollection = arguments );
		}

		var syncScripts    = _getVersionTableScriptArray();
		var versionScripts = _getSchemaVersioningService().getSetVersionPlainSql( argumentCollection=arguments );
		for( var script in versionScripts ){
			syncScripts.append( script );
		}
	}



// GETTERS AND SETTERS
	private any function _getAdapterFactory() {
		return _adapterFactory;
	}
	private void function _setAdapterFactory( required any adapterFactory ) {
		_adapterFactory = arguments.adapterFactory;
	}

	private any function _getSqlRunner() {
		return _sqlRunner;
	}
	private void function _setSqlRunner( required any sqlRunner ) {
		_sqlRunner = arguments.sqlRunner;
	}

	private any function _getDbInfoService() {
		return _dbInfoService;
	}
	private void function _setDbInfoService( required any dbInfoService ) {
		_dbInfoService = arguments.dbInfoService;
	}

	private any function _getSchemaVersioningService() {
		return _schemaVersioningService;
	}
	private void function _setSchemaVersioningService( required any schemaVersioningService ) {
		_schemaVersioningService = arguments.schemaVersioningService;
	}

	private boolean function _getAutoRunScripts() {
		return _autoRunScripts;
	}
	private void function _setAutoRunScripts( required boolean autoRunScripts ) {
		_autoRunScripts = arguments.autoRunScripts;
	}

	private boolean function _getAutoRestoreDeprecatedFields() {
		return _autoRestoreDeprecatedFields;
	}
	private void function _setAutoRestoreDeprecatedFields( required boolean autoRestoreDeprecatedFields ) {
		_autoRestoreDeprecatedFields = arguments.autoRestoreDeprecatedFields;
	}
}