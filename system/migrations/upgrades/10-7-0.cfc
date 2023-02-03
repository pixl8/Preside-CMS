/**
 * DB Data migration upgrade script for PresideCMS 10.7.0
 *
 */
component {

	// run the migration
	public void function run( coldbox ) {
		_addLatestVersionValuesToVersionTables( coldbox );
	}

// private helpers
	private void function _addLatestVersionValuesToVersionTables( coldbox ) {
		var presideObjectService = coldbox.getWirebox().getInstance( "presideObjectService" );
		var sqlRunner            = coldbox.getWirebox().getInstance( "sqlRunner" );
		var dbInfoService        = coldbox.getWirebox().getInstance( "dbInfoService" );
		var objects              = presideObjectService.listObjects();


		for( var objectName in objects ) {
			if ( presideObjectService.objectIsVersioned( objectName ) && presideObjectService.getObjectAttribute( objectName, "dbFieldlist" ).listFindNoCase( "id" ) ) {
				var usesDrafts        = presideObjectService.objectUsesDrafts( objectName );
				var versionObjectName = presideObjectService.getVersionObjectName( objectName );
				var dbAdapter         = presideObjectService.getDbAdapterForObject( objectName );
				var dsn               = presideObjectService.getObjectAttribute( objectName, "dsn" );
				var tableName         = presideObjectService.getObjectAttribute( versionObjectName, "tablename" );
				var dbInfo            = dbInfoService.getDatabaseVersion( dsn );
				var escapedTable      = dbAdapter.escapeEntity( tableName );
				var latestAlias       = dbAdapter.escapeEntity( "latest" );
				var olderAlias        = dbAdapter.escapeEntity( "older" );
				var cleanSql          = "update #escapedTable# set _version_is_latest = '0'";
				var draftSql          = "";
				var publishedSql      = "";
				var updateData        = { _version_is_latest=false };

				if ( usesDrafts ) {
					cleanSql &= ", _version_is_latest_draft = '0'";
					updateData._version_is_latest_draft = false;
				}

				presideObjectService.updateData(
					  objectName      = versionObjectName
					, data            = updateData
					, setDateModified = false
					, useVersioning   = false
					, forceUpdateAll  = true
				);

				switch( dbInfo.database_productName ) {
					case "MySQL":
						if ( usesDrafts ) {
							draftSql     = "update    #escapedTable# #latestAlias#
							                left join #escapedTable# #olderAlias# on #olderAlias#.id = latest.id and #olderAlias#._version_number > latest._version_number
							                set       #latestAlias#._version_is_latest_draft = '1'
							                where     #olderAlias#.id is null";

							publishedSql = "update    #escapedTable# #latestAlias#
							                left join #escapedTable# #olderAlias# on #olderAlias#.id = latest.id and #olderAlias#._version_number > latest._version_number and ( #olderAlias#._version_is_draft is null or #olderAlias#._version_is_draft = '0' )
							                set       #latestAlias#._version_is_latest = '1'
							                where     #olderAlias#.id is null
							                and       ( #latestAlias#._version_is_draft is null or #latestAlias#._version_is_draft = '0' )";
						} else {
							publishedSql = "update    #escapedTable# #latestAlias#
							                left join #escapedTable# #olderAlias# on #olderAlias#.id = latest.id and #olderAlias#._version_number > latest._version_number
							                set       #latestAlias#._version_is_latest = '1'
							                where     #olderAlias#.id is null";
						}
					break;

					case "Microsoft SQL Server":
						if ( usesDrafts ) {
							draftSql     = "update    #latestAlias#
							                set       #latestAlias#._version_is_latest_draft = '1'
							                from      #escapedTable# #latestAlias#
							                left join #escapedTable# #olderAlias# on #olderAlias#.id = latest.id and #olderAlias#._version_number > latest._version_number
							                where     #olderAlias#.id is null";

							publishedSql = "update    #latestAlias#
							                set       #latestAlias#._version_is_latest = '1'
							                from      #escapedTable# #latestAlias#
							                left join #escapedTable# #olderAlias# on #olderAlias#.id = latest.id and #olderAlias#._version_number > latest._version_number and ( #olderAlias#._version_is_draft is null or #olderAlias#._version_is_draft = '0' )
							                where     #olderAlias#.id is null
							                and       ( #latestAlias#._version_is_draft is null or #latestAlias#._version_is_draft = '0' )";
						} else {
							publishedSql = "update    #latestAlias#
							                set       #latestAlias#._version_is_latest = '1'
							                from      #escapedTable# #latestAlias#
							                left join #escapedTable# #olderAlias# on #olderAlias#.id = latest.id and #olderAlias#._version_number > latest._version_number
							                where     #olderAlias#.id is null";
						}
					break;

					case "PostgreSQL":
						if ( usesDrafts ) {
							draftSql     = "update    #escapedTable# as #latestAlias#
															set       _version_is_latest_draft = '1'
															where not exists(
																	select 		1
																	from 			#escapedTable# as #olderAlias#
																	where			#olderAlias#.id = #latestAlias#.id
																	and 			#olderAlias#._version_number > #latestAlias#._version_number
															)";

							publishedSql = "update    #escapedTable# as #latestAlias#
											set       _version_is_latest = '1'
											where not exists (
											    select 1
											    from   #escapedTable# as #olderAlias#
											    where  #olderAlias#.id = #latestAlias#.id and #olderAlias#._version_number > #latestAlias#._version_number
											    and    ( #olderAlias#._version_is_draft is null or #olderAlias#._version_is_draft = '0' )
											)
											and 			( #latestAlias#._version_is_draft is null or #latestAlias#._version_is_draft = '0' )";
						} else {
							publishedSql = "update    #escapedTable# as #latestAlias#
											set       _version_is_latest = '1'
											where not exists (
											    select 1
											    from   #escapedTable# as #olderAlias#
											    where  #olderAlias#.id = #latestAlias#.id and #olderAlias#._version_number > #latestAlias#._version_number
											)";
						}
					break;
				}

				sqlRunner.runSql(
					  sql = cleanSql
					, dsn = dsn
				);

				if ( usesDrafts ) {
					sqlRunner.runSql(
						  sql = draftSql
						, dsn = dsn
					);
				}
				sqlRunner.runSql(
					  sql = publishedSql
					, dsn = dsn
				);
			}
		}
	}

}