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

		for ( var rawCol in [ "link", "link_title", "link_body" ] ) {
			var escapedRawCol      = dbAdapter.escapeEntity( rawCol );
			var escapedHashCol     = dbAdapter.escapeEntity( "#rawCol#_hash" );
			var hashValue          = "md5( #escapedRawCol# )";
			if ( dbInfo.database_productName  == "Microsoft SQL Server" ) {
				hashValue = "convert( NVARCHAR(32), hashbytes( 'md5', cast(#escapedRawCol#  as NVARCHAR( max )  )),2 )"
			}

			var updateSql = "update #escapedTableName#
						set #escapedHashCol# = #hashValue#
						where #escapedHashCol# is null and #escapedRawCol# is not null";
			sqlRunner.runSql(
				  sql = updateSql
				, dsn = dsn
			);
		}
	}

}