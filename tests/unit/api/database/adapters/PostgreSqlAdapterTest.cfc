<cfcomponent output="false" extends="mxunit.framework.TestCase">

	<cffunction name="test01_escapeEntity_shouldSurroundEntityInDoubleQuotes" returntype="void">
		<cfscript>
			var adapter  = _getAdapter();
			var expected = """myentity"""
			var result   = adapter.escapeEntity( "myEntity" );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test01_1_escapeEntity_shouldEscapeEachPartOfDotDelimitedEntity" returntype="void">
		<cfscript>
			var adapter  = _getAdapter();
			var expected = """some_alias_perhaps"".""some_column"""
			var result   = adapter.escapeEntity( "some_alias_perhaps.some_column" );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test02_getColumnDBType_shouldMapMediumtextToText" returntype="void">
		<cfscript>
			var adapter  = _getAdapter();
			var expected = "text";
			var result   = adapter.getColumnDBType( "mediumtext" );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test02_1_getColumnDBType_shouldMapLongtextToText" returntype="void">
		<cfscript>
			var adapter  = _getAdapter();
			var expected = "text";
			var result   = adapter.getColumnDBType( "longtext" );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test02_2_getColumnDBType_shouldMapTinyintToSmallint" returntype="void">
		<cfscript>
			var adapter  = _getAdapter();
			var expected = "smallint";
			var result   = adapter.getColumnDBType( "tinyint" );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test03_getColumnDefinitionSql_shouldReturnPostgreSqlFormattedBasicColumnDefinition" returntype="void">
		<cfscript>
			var adapter  = _getAdapter();
			var expected = """mycolumn"" varchar(200) null";
			var result   = adapter.getColumnDefinitionSql(
				  columnName = "mycolumn"
				, dbType     = "varchar"
				, maxLength  = 200
				, nullable   = true
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test03_1_getColumnDefinitionSql_shouldMapMediumtextToText" returntype="void">
		<cfscript>
			var adapter  = _getAdapter();
			var expected = """mycolumn"" text null";
			var result   = adapter.getColumnDefinitionSql(
				  columnName = "mycolumn"
				, dbType     = "mediumtext"
				, nullable   = true
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test03_2_getColumnDefinitionSql_shouldMapTinyintToSmallint" returntype="void">
		<cfscript>
			var adapter  = _getAdapter();
			var expected = """mycolumn"" smallint not null";
			var result   = adapter.getColumnDefinitionSql(
				  columnName = "mycolumn"
				, dbType     = "tinyint"
				, nullable   = false
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test04_getSelectSql_shouldStripQuotedAliasesInAutoGroupBy" returntype="void">
		<cfscript>
			var adapter    = _getAdapter();
			var result     = adapter.getSelectSql(
				  tableName     = "page"
				, selectColumns = [ "page._hierarchy_slug as ""full_slug""", "Count(*) as cnt" ]
				, groupBy       = "page._hierarchy_slug as ""full_slug"""
			);
			var groupByPos = FindNoCase( "group by", result );
			var groupBySql = groupByPos ? Mid( result, groupByPos, Len( result ) ) : "";

			super.assert( groupByPos, "Should include GROUP BY clause when aggregate functions are present" );
			super.assert( FindNoCase( "page._hierarchy_slug", groupBySql ), "Should include non-aggregate column in GROUP BY" );
			super.assert( !FindNoCase( "as ""full_slug""", groupBySql ), "Should strip quoted alias from GROUP BY clause" );
		</cfscript>
	</cffunction>

	<cffunction name="test05_getSelectSql_shouldHandleUnquotedAliasesInAutoGroupBy" returntype="void">
		<cfscript>
			var adapter    = _getAdapter();
			var result     = adapter.getSelectSql(
				  tableName     = "test"
				, selectColumns = [ "test.col as myalias", "Sum(test.value) as total" ]
				, groupBy       = "test.col as myalias"
			);
			var groupByPos = FindNoCase( "group by", result );
			var groupBySql = groupByPos ? Mid( result, groupByPos, Len( result ) ) : "";

			super.assert( groupByPos, "Should include GROUP BY clause when aggregate functions are present" );
			super.assert( FindNoCase( "test.col", groupBySql ), "Should include non-aggregate column in GROUP BY" );
			super.assert( !FindNoCase( "as myalias", groupBySql ), "Should strip unquoted alias from GROUP BY clause" );
		</cfscript>
	</cffunction>

	<cffunction name="test06_getInsertSql_shouldReturnReturningClause" returntype="void">
		<cfscript>
			var adapter  = _getAdapter();
			var expected = ["insert into ""event_category"" ( ""col_a"", ""col_b"" ) values ( :col_a, :col_b ) RETURNING *"];
			var result   = adapter.getInsertSql(
				  tableName     = "event_category"
				, insertColumns = [ "col_a", "col_b" ]
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test07_supportsUpsertSql_shouldReturnTrue" returntype="void">
		<cfscript>
			var adapter = _getAdapter();
			super.assertTrue( adapter.supportsUpsertSql() );
		</cfscript>
	</cffunction>

	<cffunction name="test08_getUpsertSql_shouldUseNullSafeCTEApproach" returntype="void">
		<cfscript>
			var adapter  = _getAdapter();
			var result   = adapter.getUpsertSql(
				  tableName       = "system_config"
				, insertColumns   = [ "category", "setting", "value", "tenant_id" ]
				, updateColumns   = [ "value" ]
				, conflictColumns = [ "category", "setting", "tenant_id" ]
			);

			super.assert( FindNoCase( "WITH upd AS", result[1] ), "Should use CTE approach with upd" );
			super.assert( FindNoCase( "ins AS", result[1] ), "Should use CTE approach with ins" );
			super.assert( FindNoCase( "IS NOT DISTINCT FROM", result[1] ), "Should use IS NOT DISTINCT FROM for NULL-safe comparison" );
			super.assert( FindNoCase( "UNION ALL", result[1] ), "Should use UNION ALL to combine UPDATE and INSERT results" );
			super.assert( !FindNoCase( "ON CONFLICT", result[1] ), "Should not use ON CONFLICT approach" );
		</cfscript>
	</cffunction>

	<cffunction name="test09_sqlDataTypeToCfSqlDatatype_shouldReturnCfEquivalentForPostgreSqlDatatypes" returntype="void">
		<cfscript>
			var adapter = _getAdapter();
			var matrix  = {
				  cf_sql_bigint        = [ "bigint signed", "int unsigned", "bigint"                                             ]
				, cf_sql_integer       = [ "mediumint signed", "mediumint unsigned", "int signed", "mediumint", "int", "integer" ]
				, cf_sql_smallint      = [ "smallint signed", "smallint unsigned", "tinyint signed", "tinyint", "smallint"       ]
				, cf_sql_timestamp     = [ "datetime", "timestamp"                                                               ]
				, cf_sql_longvarchar   = [ "text", "mediumtext", "longtext"                                                      ]
			};
			var cfType    = "";
			var pgType    = "";
			var result    = "";

			for( cfType in matrix ){
				for( pgType in matrix[ cfType ] ) {
					result = adapter.sqlDataTypeToCfSqlDatatype( pgType );
					super.assertEquals( cfType, result, "Cf type for [#pgType#] should be [#cfType#]. [#result#] was returned instead" );
				}
			}
		</cfscript>
	</cffunction>

	<cffunction name="test10_getSelectSql_shouldUseLimitOffsetSyntax" returntype="void">
		<cfscript>
			var adapter  = _getAdapter();
			var expected = """id"" from ""event"" limit 10 offset 10";
			var result   = adapter.getSelectSql(
				  tableName     = "event"
				, selectColumns = [ """id""" ]
				, maxRows       = 10
				, startRow      = 11
			);

			super.assert( FindNoCase( expected, result ), "Should use LIMIT OFFSET syntax" );
		</cfscript>
	</cffunction>

	<cffunction name="test11_getSelectSql_shouldHandleGroupByWithoutWhereClause" returntype="void">
		<cfscript>
			var adapter  = _getAdapter();
			var result   = adapter.getSelectSql(
				  tableName     = "admin_notification"
				, tableAlias    = "admin_notification"
				, selectColumns = [ "admin_notification.topic" ]
				, groupBy       = "group by admin_notification.topic"
			);

			super.assert( FindNoCase( "select", result ), "Should include SELECT keyword" );
			super.assert( !ReFindNoCase( "^\s*,", result ), "Should not start with a comma" );
			super.assert( FindNoCase( "admin_notification.topic", result ), "Should include grouped column" );
			super.assert( FindNoCase( "as Temp", result ), "Should include Temp subquery alias" );
		</cfscript>
	</cffunction>

	<cffunction name="test12_getUpsertSql_shouldUseSelectFormNotValues" returntype="void">
		<cfscript>
			var adapter  = _getAdapter();
			var result   = adapter.getUpsertSql(
				  tableName       = "system_config"
				, insertColumns   = [ "category", "setting", "value", "tenant_id", "site" ]
				, updateColumns   = [ "value" ]
				, conflictColumns = [ "category", "setting", "tenant_id", "site" ]
			);

			super.assert( FindNoCase( "WITH upd AS", result[1] ), "Should use CTE approach with upd" );
			super.assert( FindNoCase( "ins AS", result[1] ), "Should use CTE approach with ins" );
			super.assert( FindNoCase( "IS NOT DISTINCT FROM", result[1] ), "Should use IS NOT DISTINCT FROM for NULL-safe comparison" );
			super.assert( FindNoCase( "INSERT INTO", result[1] ), "Should use INSERT INTO" );
			super.assert( FindNoCase( "SELECT :", result[1] ), "Should use SELECT form for insert values" );
			super.assert( !FindNoCase( "values (", result[1] ), "Should not use VALUES form" );
			super.assert( FindNoCase( "UNION ALL", result[1] ), "Should use UNION ALL to return rows from both UPDATE and INSERT paths" );
			super.assert( FindNoCase( "SELECT * FROM upd", result[1] ), "Should select from upd CTE to return updated rows" );
			super.assert( FindNoCase( "SELECT * FROM ins", result[1] ), "Should select from ins CTE to return inserted rows" );
			super.assert( !FindNoCase( "ON CONFLICT", result[1] ), "Should not use ON CONFLICT" );
		</cfscript>
	</cffunction>

<!--- test helpers --->
	<cffunction name="_getAdapter" access="private" returntype="any" output="false">
		<cfscript>
			var mockedDbInfo = querySim( "database_productname,database_version
			    PostgreSQL | 18.0.0"
			);

			return new preside.system.services.database.adapters.PostgreSqlAdapter( dbInfo=mockedDbInfo, dsn="preside" );
		</cfscript>
	</cffunction>
</cfcomponent>
