<cfcomponent output="false" extends="mxunit.framework.TestCase">

	<cffunction name="test01_escapeEntity_shouldSurroundEntityInBackTicks" returntype="void">
		<cfscript>
			var adapter  = _getAdapter();
			var expected = "`myEntity`"
			var result   = adapter.escapeEntity( "myEntity" );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test01_1_escapeEntity_shouldEscapeEachPartOfDotDelimitedEntity" returntype="void">
		<cfscript>
			var adapter = _getAdapter();
			var expected = "`some_alias_perhaps`.`some_column`"
			var result   = adapter.escapeEntity( "some_alias_perhaps.some_column" );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test02_getColumnDefinitionSql_shouldReturnMySqlFormattedBasicColumnDefinition" returntype="void">
		<cfscript>
			var adapter  = _getAdapter();
			var expected = "`mycolumn` varchar(200) null";
			var result   = adapter.getColumnDefinitionSql(
				  columnName = "mycolumn"
				, dbType     = "varchar"
				, maxLength  = 200
				, nullable   = true
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test02_1_getColumnDefinitionSql_shouldDefineVarcharWithUtf8Max_whenZeroIsSpecified" returntype="void">
		<cfscript>
			var adapter  = _getAdapter();
			var expected = "`varchar_column` varchar(200) null";
			var result   = adapter.getColumnDefinitionSql(
				  columnName = "varchar_column"
				, dbType     = "varchar"
				, maxLength  = 0
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test03_getColumnDefinitionSql_shouldReturnMySqlFormattedBasicColumnDefinition_withNotNull_andNoMaxSizeBounds" returntype="void">
		<cfscript>
			var adapter  = _getAdapter();
			var expected = "`mycolumn` int not null";
			var result   = adapter.getColumnDefinitionSql(
				  columnName = "mycolumn"
				, dbType     = "int"
				, nullable   = false
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test05_getColumnDefinitionSql_shouldReturnWellFormattedPrimaryKey" returntype="void">
		<cfscript>
			var adapter  = _getAdapter();
			var expected = "`id` varchar(35) not null primary key";
			var result   = adapter.getColumnDefinitionSql(
				  columnName   = "id"
				, dbType       = "varchar"
				, maxLength    = 35
				, nullable     = true
				, primaryKey   = true
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test06_getColumnDefinitionSql_shouldReturnWellFormattedAutoIncrementingPrimaryKey" returntype="void">
		<cfscript>
			var adapter  = _getAdapter();
			var expected = "`id` int not null auto_increment primary key";
			var result   = adapter.getColumnDefinitionSql(
				  columnName    = "id"
				, dbType        = "int"
				, nullable      = true
				, primaryKey    = true
				, autoIncrement = true
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test07_getTableDefinitionSql_shouldReturnWellFormedCreateTableStatement" returntype="void">
		<cfscript>
			var adapter = _getAdapter();
			var expected = "create table `some_table` ( `field1` int not null auto_increment primary key, `field2` bit null, `field3` varchar(30) null ) ENGINE=InnoDB";
			var result  = adapter.getTableDefinitionSql(
				  tableName="some_table"
				, columnSql = "`field1` int not null auto_increment primary key, `field2` bit null, `field3` varchar(30) null"
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test08_getForeignKeyConstraintSql_shouldReturnWellFormattedSql_withDefaultOnDeleteAndOnUpdateRules" returntype="void">
		<cfscript>
			var adapter  = _getAdapter();
			var expected = "alter table `source_table` add constraint `fk_name` foreign key ( `source_col` ) references `foreign_table` ( `foreign_col` ) on delete set null on update cascade";
			var result   = adapter.getForeignKeyConstraintSql(
				  sourceTable    = "source_table"
				, sourceColumn   = "source_col"
				, constraintName = "fk_name"
				, foreignTable   = "foreign_table"
				, foreignColumn  = "foreign_col"
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test09_getForeignKeyConstraintSql_shouldReturnWellFormattedSql_withPassedOnDeleteAndOnUpdateRules" returntype="void">
		<cfscript>
			var adapter  = _getAdapter();
			var expected = "alter table `source_table` add constraint `fk_name` foreign key ( `source_col` ) references `foreign_table` ( `foreign_col` ) on delete cascade on update set null";
			var result   = adapter.getForeignKeyConstraintSql(
				  sourceTable    = "source_table"
				, sourceColumn   = "source_col"
				, constraintName = "fk_name"
				, foreignTable   = "foreign_table"
				, foreignColumn  = "foreign_col"
				, onDelete       = "cascade"
				, onUpdate       = "set null"
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test09_2_getForeignKeyConstraintSql_shouldReturnWellFormattedSql_withNoOnDeleteOrOnUpdateRule_whenPassedValuesAreEqualToError" returntype="void">
		<cfscript>
			var adapter  = _getAdapter();
			var expected = "alter table `source_table` add constraint `fk_name` foreign key ( `source_col` ) references `foreign_table` ( `foreign_col` )";
			var result   = adapter.getForeignKeyConstraintSql(
				  sourceTable    = "source_table"
				, sourceColumn   = "source_col"
				, constraintName = "fk_name"
				, foreignTable   = "foreign_table"
				, foreignColumn  = "foreign_col"
				, onDelete       = "error"
				, onUpdate       = "error"
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>


	<cffunction name="test10_getIndexSql_shouldReturnWellFormedIndexSql" returntype="void">
		<cfscript>
			var adapter  = _getAdapter();
			var expected = "create index `ix_index` on `table_name` ( `col1`, `col2`, `col3` )";
			var result   = adapter.getIndexSql(
				  indexName = "ix_index"
				, tableName = "table_name"
				, fieldList = "col1,col2,col3"
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test11_getIndexSql_shouldReturnWellFormedUniqueIndexSql" returntype="void">
		<cfscript>
			var adapter  = _getAdapter();
			var expected = "create unique index `ux_index` on `table_name` ( `col1`, `col2`, `col3` )";
			var result   = adapter.getIndexSql(
				  indexName = "ux_index"
				, tableName = "table_name"
				, fieldList = "col1,col2,col3"
				, unique    = true
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test14_getAlterColumnSql_shouldReturnWellFormedSqlForAlteringAColumn" returntype="void">
		<cfscript>
			var adapter  = _getAdapter();
			var expected = "alter table `my_table` change `id` `id` int not null auto_increment";
			var result   = adapter.getAlterColumnSql(
				  tableName     = "my_table"
				, columnName    = "id"
				, dbType        = "int"
				, nullable      = false
				, autoIncrement = true
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test15_getAlterColumnSql_shouldNotIncludePrimaryKeyAssignment_whenColumnIsPrimaryKey_becauseMySqlBarfsClaimingMultiplePks" returntype="void">
		<cfscript>
			var adapter  = _getAdapter();
			var expected = "alter table `my_table` change `id` `id` varchar(35) not null";
			var result   = adapter.getAlterColumnSql(
				  tableName     = "my_table"
				, columnName    = "id"
				, dbType        = "varchar"
				, maxLength     = "35"
				, nullable      = false
				, autoIncrement = false
				, primaryKey    = true
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test16_getAlterColumnSql_shouldBeAbleToRenameColumn" returntype="void">
		<cfscript>
			var adapter  = _getAdapter();
			var expected = "alter table `my_table` change `col_a` `new_name` varchar(35) not null";
			var result   = adapter.getAlterColumnSql(
				  tableName     = "my_table"
				, columnName    = "col_a"
				, newName       = "new_name"
				, dbType        = "varchar"
				, maxLength     = "35"
				, nullable      = false
				, autoIncrement = false
				, primaryKey    = true
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test17_getAddColumnSql_shouldReturnWellFormedAddColumnStatement" returntype="void">
		<cfscript>
			var adapter  = _getAdapter();
			var expected = "alter table `my_table` add `id` varchar(35) not null primary key";
			var result   = adapter.getAddColumnSql(
				  tableName     = "my_table"
				, columnName    = "id"
				, dbType        = "varchar"
				, maxLength     = "35"
				, nullable      = false
				, autoIncrement = false
				, primaryKey    = true
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test18_getDropIndexSql_shouldReturnWellFormedDropIndexStatement" returntype="void">
		<cfscript>
			var adapter = _getAdapter();
			var expected = "alter table `some_table` drop index `ix_my_index`";
			var result = adapter.getDropIndexSql(
				  tableName = "some_table"
				, indexName = "ix_my_index"
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test19_getDropForeignKeySql_shouldReturnWellFormedDropForeignKeySql" returntype="void">
		<cfscript>
			var adapter = _getAdapter();
			var expected = "alter table `some_table` drop foreign key `fk_foreign_key__here__yes`";
			var result = adapter.getDropForeignKeySql(
				  tableName      = "some_table"
				, foreignKeyName = "fk_foreign_key__here__yes"
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test20_getUpdateSql_shouldReturnSimpleUpdateSql" returntype="void">
		<cfscript>
			var adapter = _getAdapter();
			var expected = "update `a_table` set `column_a` = :set__column_a, `column_b` = :set__column_b where `column_c` = :column_c and `column_d` = :column_d";
			var result = adapter.getUpdateSql(
				  tableName     = "a_table"
				, updateColumns = [ "column_a", "column_b" ]
				, filter        = { column_c="test", column_d=4 }
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test20_1_getUpdateSql_shouldReturnUpdateSqlWithJoins_whenJoinsPassed" returntype="void">
		<cfscript>
			var adapter = _getAdapter();
			var expected = "update `event` `e` inner join `cat` `c` on (`c`.`id` = `e`.`cat`) left join `test` `t` on (`t`.`col` = `c`.`test`) set `e`.`column_a` = :set__column_a, `e`.`column_b` = :set__column_b where `cat`.`column_d` = :cat__column_d and `e`.`column_c` = :column_c";
			var result = adapter.getUpdateSql(
				  tableName     = "event"
				, tableAlias    = "e"
				, updateColumns = [ "column_a", "column_b" ]
				, filter        = { column_c="test", "cat.column_d"=4 }
				, joins         = [{
					  tableName    = "cat"
					, tableAlias   = "c"
					, tableColumn  = "id"
					, joinToTable  = "e"
					, joinToColumn = "cat"
					, type         = "inner"

				  },{
					  tableName    = "test"
					, tableAlias   = "t"
					, tableColumn  = "col"
					, joinToTable  = "c"
					, joinToColumn = "test"
					, type         = "left"

				  }]
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test20_2_getUpdateSql_shouldReturnUpdateSql_withPlainTextFilter" returntype="void">
		<cfscript>
			var adapter = _getAdapter();
			var expected = "update `a_table` set `column_a` = :set__column_a, `column_b` = :set__column_b where this.is > :my__filter or test = :nice__test";
			var result = adapter.getUpdateSql(
				  tableName     = "a_table"
				, updateColumns = [ "column_a", "column_b" ]
				, filter        = "this.is > :my.filter or test = :nice.test"
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test21_getDeleteSql_shouldReturnSimpleDeleteSql" returntype="void">
		<cfscript>
			var adapter = _getAdapter();
			var expected = "delete from `test_table` where `another_col` = :another_col and `my_column` = :my_column";
			var result = adapter.getDeleteSql(
				  tableName = "test_table"
				, filter    = { my_column="test", another_col="test" }
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test21_1_getDeleteSql_shouldWorkWithPlainTextFilte" returntype="void">
		<cfscript>
			var adapter = _getAdapter();
			var expected = "delete from `test_table` where myfilter > :your__filter";
			var result = adapter.getDeleteSql(
				  tableName = "test_table"
				, filter    = "myfilter > :your.filter"
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test22_getInsertSql_shouldReturnSimpleInsertSql" returntype="void">
		<cfscript>
			var adapter = _getAdapter();
			var expected = ["insert into `event_category` ( `col_a`, `col_b`, `col_c` ) values ( :col_a, :col_b, :col_c )"];
			var result = adapter.getInsertSql(
				  tableName     = "event_category"
				, insertColumns = [ "col_a", "col_b", "col_c" ]
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test23_getInsertSql_shouldReturnMultiInsertSql_whenMoreThanOneRowSpecified" returntype="void">
		<cfscript>
			var adapter = _getAdapter();
			var expected = ["insert into `event_category` ( `col_a`, `col_b`, `col_c` ) values ( :col_a_1, :col_b_1, :col_c_1 ), ( :col_a_2, :col_b_2, :col_c_2 ), ( :col_a_3, :col_b_3, :col_c_3 )"];
			var result = adapter.getInsertSql(
				  tableName     = "event_category"
				, insertColumns = [ "col_a", "col_b", "col_c" ]
				, noOfRows      = 3
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test23a_getInsertSql_shouldReturnInsertSqlWithSelectData_whenSelectStatementProvided" returntype="void">
		<cfscript>
			var adapter   = _getAdapter();
			var selectSql = "select col_a, col_b, col_c from blah where foo = :bar";
			var expected  = [ "insert into `event_category` ( `col_a`, `col_b`, `col_c` ) #selectSql#" ];
			var result    = adapter.getInsertSql(
				  tableName     = "event_category"
				, insertColumns = [ "col_a", "col_b", "col_c" ]
				, selectStatement = selectSql
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test24_getSelectSql_shouldReturnSimpleSelectSql" returntype="void">
		<cfscript>
			var adapter = _getAdapter();
			var expected = "select `id`, label, event_date from `event` where `event_category`.`test` = :event_category__test and `event_date` = :event_date order by event_category, sort_order desc";
			var result = adapter.getSelectSql(
				  tableName     = "event"
				, selectColumns = [ "`id`", "label", "event_date" ]
				, filter        = { "event_category.test" = "test", event_date="2012-09-21" }
				, orderBy       = "event_category, sort_order desc"
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test24_1_getSelectSql_shouldWorkWithPlainTextFilter" returntype="void">
		<cfscript>
			var adapter = _getAdapter();
			var expected = "select `id`, label, event_date from `event` where event_category.test = :test and DateDiff( event_date, Now() ) > :date__diff order by event_category, sort_order desc";
			var result = adapter.getSelectSql(
				  tableName     = "event"
				, selectColumns = [ "`id`", "label", "event_date" ]
				, filter        = "event_category.test = :test and DateDiff( event_date, Now() ) > :date.diff"
				, orderBy       = "event_category, sort_order desc"
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test25_getSelectSql_shouldAllowForJoinSpecifications" returntype="void">
		<cfscript>
			var adapter = _getAdapter();
			var expected = "select e.col from `event` `e` inner join `cat` `c` on (`c`.`id` = `e`.`cat`) and (`blah` = `blah`) left join `test` `t` on (`t`.`col` = `c`.`test`)";
			var result = adapter.getSelectSql(
				  tableName     = "event"
				, tableAlias    = "e"
				, selectColumns = [ "e.col" ]
				, joins         = [{
					  tableName    = "cat"
					, tableAlias   = "c"
					, tableColumn  = "id"
					, joinToTable  = "e"
					, joinToColumn = "cat"
					, type         = "inner"
					, additionalClauses = "`blah` = `blah`"

				  },{
					  tableName    = "test"
					, tableAlias   = "t"
					, tableColumn  = "col"
					, joinToTable  = "c"
					, joinToColumn = "test"
					, type         = "left"

				  }]
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test25_1_getSelectSql_shouldAllowGroupBySpecification" returntype="void">
		<cfscript>
			var adapter = _getAdapter();
			var expected = "select `id`, label, Count(*) as counts from `event` where `event_category`.`test` = :event_category__test and `event_date` = :event_date group by `id` order by event_category, sort_order desc";
			var result = adapter.getSelectSql(
				  tableName     = "event"
				, selectColumns = [ "`id`", "label", "Count(*) as counts" ]
				, filter        = { "event_category.test" = "test", event_date="2012-09-21" }
				, orderBy       = "event_category, sort_order desc"
				, groupBy       = "`id`"
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test26_getSelectSql_shouldThrowMeaningfulError_whenJoinsAreNotSpecifiedWithRequiredFields" returntype="void">
		<cfscript>
			var adapter     = _getAdapter();
			var errorThrown = false;

			try {
				adapter.getSelectSql(
					  tableName     = "event"
					, tableAlias    = "e"
					, selectColumns = [ "e.col" ]
					, joins         = [{
						  tableName    = "cat"
						, tableAlias   = "c"
						, tableColumn  = "id"
						, joinToTable  = "event"
						, joinToColumn = "cat"
						, type         = "inner"

					  },{}]
				);

			} catch( "MySqlAdapter.missingJoinParams" e ){
				super.assertEquals( "Missing param in supplied join. Required params are [tableName], [tableColumn], [joinToTable] and [joinToColumn]", e.message );
				super.assertEquals( "[tableName] was not supplied", e.detail );
				errorThrown = true;
			}


			super.assert( errorThrown, "A meaninful and helpful error was not thrown" );
		</cfscript>
	</cffunction>

	<cffunction name="test26_1_getSelectSql_shouldReturnSqlWithLIMITSyntax_whenMaxRowsSpecified" returntype="void">
		<cfscript>
			var adapter = _getAdapter();
			var expected = "select `id` from `event` limit 0, 10";
			var result = adapter.getSelectSql(
				  tableName     = "event"
				, selectColumns = [ "`id`" ]
				, maxRows       = 10
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test26_2_getSelectSql_shouldReturnSqlWithLIMITSyntax_whenStartRowAndMaxRowsSpecified" returntype="void">
		<cfscript>
			var adapter = _getAdapter();
			var expected = "select `id` from `event` limit 10, 10";
			var result = adapter.getSelectSql(
				  tableName     = "event"
				, selectColumns = [ "`id`" ]
				, maxRows       = 10
				, startRow      = 11
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test27_sqlDataTypeToCfSqlDatatype_shouldReturnCfEquivalentForAllMySqlDatatypes" returntype="void">
		<cfscript>
			var adapter = _getAdapter();
			var matrix = {
				  cf_sql_bigint        = [ "bigint signed", "int unsigned", "bigint"                                             ]
				, cf_sql_binary        = [ "binary"                                                                              ]
				, cf_sql_bit           = [ "bit", "bool"                                                                         ]
				, cf_sql_blob          = [ "blob"                                                                                ]
				, cf_sql_char          = [ "char"                                                                                ]
				, cf_sql_date          = [ "date"                                                                                ]
				, cf_sql_decimal       = [ "decimal"                                                                             ]
				, cf_sql_double        = [ "double", "double precision", "real"                                                  ]
				, cf_sql_integer       = [ "mediumint signed", "mediumint unsigned", "int signed", "mediumint", "int", "integer" ]
				, cf_sql_longvarbinary = [ "mediumblob","longblob","tinyblob"                                                    ]
				, cf_sql_clob          = [ "text","mediumtext","longtext"                                                        ]
				, cf_sql_numeric       = [ "numeric", "bigint unsigned"                                                          ]
				, cf_sql_real          = [ "float"                                                                               ]
				, cf_sql_smallint      = [ "smallint signed", "smallint unsigned", "tinyint signed", "tinyint", "smallint"       ]
				, cf_sql_timestamp     = [ "datetime","timestamp"                                                                ]
				, cf_sql_tinyint       = [ "tinyint unsigned"                                                                    ]
				, cf_sql_varbinary     = [ "varbinary"                                                                           ]
				, cf_sql_varchar       = [ "varchar", "tinytext", "enum", "set"                                                  ]
			};
			var cfType = "";
			var mysqlType = "";
			var result = "";

			for( cfType in matrix ){
				for( mysqlType in matrix[ cfType ] ) {
					result = adapter.sqlDataTypeToCfSqlDatatype( mysqlType );
					super.assertEquals( cfType, result, "Cf type for [#mysqlType#] should be [#cfType#]. [#result#] was returned instead" );
				}
			}
		</cfscript>
	</cffunction>

	<cffunction name="test28_getClauseSql_shouldReturnEmptyString_whenNoFilterSupplied" returntype="void">
		<cfscript>
			var adapter = _getAdapter();
			var expected = "";
			var result = adapter.getClauseSql( filter={} );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test29_getClauseSql_shouldReturnSimpleSql_whenFiltersSupplied" returntype="void">
		<cfscript>
			var adapter = _getAdapter();
			var expected = " where `another_col` = :another_col and `some_col` = :some_col";
			var result = adapter.getClauseSql( filter={
				  some_col    = "blah"
				, another_col = "test"
			} );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test29_1_getClauseSql_shouldAddAliasesToBareColumns_whenTableAliasSupplied" returntype="void">
		<cfscript>
			var adapter = _getAdapter();
			var expected = " where `blah`.`another_col` = :blah__another_col and `alias`.`some_col` = :some_col";
			var result = adapter.getClauseSql( tableAlias="alias", filter={
				  some_col           = "blah"
				, "blah.another_col" = "test"
			} );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test30_getClauseSql_shouldUse_IN_syntax_whenValueIsAnArray" returntype="void">
		<cfscript>
			var adapter = _getAdapter();
			var expected = " where `some_col` in ( :some_col )"
			var result = adapter.getClauseSql( filter={
				  some_col = [ "blah", "yeah", "fubar", "test" ]
			} );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test31_getClauseSql_shouldPrependWHEREToSuppliedFilter_whenFilterIsAString" returntype="void">
		<cfscript>
			var adapter = _getAdapter();
			var expected = " where ( this = :that or test = :whatever )"
			var result = adapter.getClauseSql( filter="( this = :that or test = :whatever )" );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test32_getClauseSql_shouldReplaceDotsWithDoubleUnderscoresFromFilterParams_whenFilterIsAString" returntype="void">
		<cfscript>
			var adapter = _getAdapter();
			var expected = " where ( this.that = :that__this or test.fubar = :whatever__test )"
			var result = adapter.getClauseSql( filter="( this.that = :that.this or test.fubar = :whatever.test )" );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test33_getCountSql_shouldReturnTheGivenCompleteSqlQueryWrappedInACountStatement" returntype="void">
		<cfscript>
			var adapter     = _getAdapter();
			var originalSql = "select id from sometable";
			var expected    = "select count(1) as `record_count` from ( select id from sometable ) `original_statement`"
			var result      = adapter.getCountSql( originalStatement=originalSql );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test34_getSelectSql_shouldAllowHavingSpecification" returntype="void">
		<cfscript>
			var adapter = _getAdapter();
			var expected = "select `id`, label, Count(*) as counts from `event` where `event_category`.`test` = :event_category__test and `event_date` = :event_date group by `id` having count(1) > 4 order by event_category, sort_order desc";
			var result = adapter.getSelectSql(
				  tableName     = "event"
				, selectColumns = [ "`id`", "label", "Count(*) as counts" ]
				, filter        = { "event_category.test" = "test", event_date="2012-09-21" }
				, orderBy       = "event_category, sort_order desc"
				, groupBy       = "`id`"
				, having        = "Count(1) > 4"
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

<!--- te helpers --->
	<cffunction name="_getAdapter" access="private" returntype="any" output="false">
		<cfreturn new preside.system.services.database.adapters.MySqlAdapter( argumentCollection = arguments ) />
	</cffunction>
</cfcomponent>