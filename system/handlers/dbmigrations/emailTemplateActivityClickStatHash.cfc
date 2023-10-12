component {

	private void function run() {
		var presideObjectService = getController().getWirebox().getInstance( "presideObjectService" );
		var dbInfoService        = getController().getWirebox().getInstance( "dbInfoService" );
		var sqlRunner            = getController().getWirebox().getInstance( "sqlRunner" );
		var objectName           = "email_template_send_log_activity";
		var dbAdapter            = presideObjectService.getDbAdapterForObject( objectName );
		var dsn                  = presideObjectService.getObjectAttribute( objectName, "dsn" );
		var tableName            = presideObjectService.getObjectAttribute( objectName, "tablename" );
		var dbInfo               = dbInfoService.getDatabaseVersion( dsn );
		var escapedTableName     = dbAdapter.escapeEntity( tableName );
		var updateHashCols       = [];
		var addTempColSqlArray   = [];
		var dropTempColSqlArray  = [];
		var addTempIndexSql      = "";
		var dropTempIndexSql     = "";

		for ( var rawCol in [ "link", "link_title", "link_body" ] ) {
			var escapedRawCol      = dbAdapter.escapeEntity( rawCol );
			var escapedHashCol     = dbAdapter.escapeEntity( "#rawCol#_hash" );
			var escapedHashTempCol = dbAdapter.escapeEntity( "#rawCol#_hash_temp" );

			var addTempColSql  = "";
			var dropTempColSql = "";

			switch ( dbInfo.database_productName ) {
				case "MySQL":
					addTempColSql = "alter table #escapedTableName#
									add column #escapedHashTempCol# varChar( 32 ) generated always as ( md5( #escapedRawCol# ) )
									";
					dropTempColSql = "alter table #escapedTableName#
									drop column #escapedHashTempCol#
									";
				break;
				case "Microsoft SQL Server":
					addTempColSql = "alter table #escapedTableName#
									add #escapedHashTempCol# as convert( NVARCHAR(32), hashbytes( 'md5', cast(#escapedRawCol#  as NVARCHAR( max )  )),2 ) 
									";
					dropTempColSql = "alter table #escapedTableName#
									drop column #escapedHashTempCol#
									";
				case "PostgreSQL":
					addTempColSql = "alter table #escapedTableName#
									add column #escapedHashTempCol# varChar(32) generated always as ( md5( #escapedRawCol# ) ) stored;
									";
					dropTempColSql = "alter table #escapedTableName#
									drop column #escapedHashTempCol#
									";
				break;
			}

			if ( rawCol == "link" ) {
				var escapedTempIndex = dbAdapter.escapeEntity( "temp_ix_link_hash_temp" );
				switch ( dbInfo.database_productName ) {
					case "MySQL":
						addTempIndexSql = "alter table #escapedTableName#
											  add index #escapedTempIndex# (#escapedHashTempCol#) 
											";
						dropTempIndexSql = "alter table #escapedTableName#
											drop index #escapedTempIndex# 
											";
					break;
					case "Microsoft SQL Server":
						addTempIndexSql = "create index #escapedTempIndex#
											on #escapedTableName# ( #escapedHashTempCol# )
											";
						dropTempIndexSql = "drop index #escapedTableName#.#escapedTempIndex#";
					case "PostgreSQL":
						addTempIndexSql = "create index #escapedTempIndex#
										   on #escapedTableName# ( #escapedHashTempCol# )
										   ";
						dropTempIndexSql = "drop index #escapedTempIndex#";
					break;
				}
			}

			if ( len( trim ( addTempColSql ) ) ) {
				arrayAppend( addTempColSqlArray , addTempColSql  );
				arrayAppend( dropTempColSqlArray, dropTempColSql );
				arrayAppend( updateHashCols     , "#escapedHashCol# = #escapedHashTempCol#");
			}
		}

		// Add temp col
		for ( var sql in addTempColSqlArray ) {
			sqlRunner.runSql(
				  sql = sql
				, dsn = dsn
			);
		}
		// Add index
		sqlRunner.runSql(
			  sql = addTempIndexSql
			, dsn = dsn
		);

		// Update data
		var updateSql = "update #escapedTableName#
						set #arrayToList( updateHashCols )#
						where #dbAdapter.escapeEntity( "link_hash_temp" )# != '#hash( '' )#'";
		sqlRunner.runSql(
			  sql = updateSql
			, dsn = dsn
		);

		// Drop temp index
		sqlRunner.runSql(
			  sql = dropTempIndexSql
			, dsn = dsn
		);

		// Drop temp col
		for ( var sql in dropTempColSqlArray ) {
			sqlRunner.runSql(
				  sql = sql
				, dsn = dsn
			);
		}
	}

}