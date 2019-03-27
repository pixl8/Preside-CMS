/**
 * DB Data migration upgrade script for PresideCMS 10.7.0
 *
 */
component {

	// run the migration
	public void function run( coldbox ) {
		_convertOldEmailActivityClicks( coldbox );
	}

// private helpers
	private void function _convertOldEmailActivityClicks( coldbox ) {
		var presideObjectService = coldbox.getWirebox().getInstance( "presideObjectService" );
		var dbInfoService        = coldbox.getWirebox().getInstance( "dbInfoService" );
		var sqlRunner            = coldbox.getWirebox().getInstance( "sqlRunner" );
		var objectName           = "email_template_send_log_activity";
		var dbAdapter            = presideObjectService.getDbAdapterForObject( objectName );
		var dsn                  = presideObjectService.getObjectAttribute( objectName, "dsn" );
		var tableName            = presideObjectService.getObjectAttribute( objectName, "tablename" );
		var dbInfo               = dbInfoService.getDatabaseVersion( dsn );
		var escapedTableName     = dbAdapter.escapeEntity( tableName );
		var escapedLinkCol       = dbAdapter.escapeEntity( "link" );
		var escapedDataCol       = dbAdapter.escapeEntity( "extra_data" );

		if ( dbInfo.database_productName == "Microsoft SQL Server" ) {
			var sql = "update #escapedTableName#
			           set #escapedLinkCol# = Replace( Replace( cast( #escapedDataCol# as varchar ), '{""link"":""', '' ), '""}', '' )
			           where #escapedDataCol# is not null
			           and cast( #escapedDataCol# as varchar ) != '{}'";
		} else {
			var sql = "update #escapedTableName#
			           set #escapedLinkCol# = Replace( Replace( #escapedDataCol#, '{""link"":""', '' ), '""}', '' )
			           where #escapedDataCol# is not null
			           and #escapedDataCol# != '{}'";
		}

		sqlRunner.runSql(
			  sql = sql
			, dsn = dsn
		);
	}

}