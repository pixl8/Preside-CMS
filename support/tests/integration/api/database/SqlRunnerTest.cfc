<cfcomponent output="false" extends="mxunit.framework.TestCase">


	<cffunction name="test01_runSql_shouldLogSqlUsedToProvidedLogger_whenLoggerIsInDebugLevel" returntype="void">
		<cfscript>
			var logger = new tests.resources.HelperObjects.TestLogger( logLevel = "DEBUG" );
			var runner = _getRunner( logger );
			var sqlStatements = [
				  "create table some_table ( some_table_id int )"
				, "insert into some_table values ( 1 ), ( 2 ), ( 3 )"
				, "insert into some_table values ( 1 ), ( 2 ), ( 3 )"
				, "select some_table_id from some_table where some_table_id = 1"
				, "drop table some_table"
			];
			var sql = "";
			var logs = "";
			var i = "";

			for( sql in sqlStatements ) {
				runner.runSql( dsn = application.dsn, sql = sql );
			}

			logs = logger.getLogs();
			super.assertEquals( ArrayLen( sqlStatements ), ArrayLen( logs ) );
			for( i=1; i lte ArrayLen( sqlStatements ); i++ ){
				super.assertEquals( "DEBUG: #sqlStatements[i]#", logs[i] );
			}
		</cfscript>
	</cffunction>

	<cffunction name="test02_runSql_shouldNotLogSqlUsedToProvidedLogger_whenLoggerIsInNonDebugLevel" returntype="void">
		<cfscript>
			var logger = new tests.resources.HelperObjects.TestLogger( logLevel = "INFORMATION" );
			var runner = _getRunner( logger );
			var sqlStatements = [
				  "create table some_table ( some_table_id int )"
				, "insert into some_table values ( 1 ), ( 2 ), ( 3 )"
				, "insert into some_table values ( 1 ), ( 2 ), ( 3 )"
				, "select some_table_id from some_table where some_table_id = 1"
				, "drop table some_table"
			];
			var sql = "";
			var logs = "";
			var i = "";

			for( sql in sqlStatements ) {
				runner.runSql( dsn = application.dsn, sql = sql );
			}

			logs = logger.getLogs();
			super.assertEquals( 0, ArrayLen( logs ) );
		</cfscript>
	</cffunction>

	<cffunction name="test03_runSql_shouldThrowInformativeError_whenParamContainsComplexValue" returntype="void">
		<cfscript>
			var logger = new tests.resources.HelperObjects.TestLogger( logLevel = "INFORMATION" );
			var runner = _getRunner( logger );
			var errorThrown = false;

			try {
				runner.runSql( dsn = application.dsn, sql = "select * from test where col = :some_value", params = [
					{ name="some_value", value={complex="value should not be accepted"}, type="cf_sql_varchar" }
				] );
			} catch ( "SqlRunner.BadParam" e ) {
				super.assertEquals( "SQL Param values must be simple values", e.message );
				super.assertEquals( "The value of the param, [some_value], was not of a simple type", e.detail )
				errorThrown = true;
			}

			super.assert( errorThrown, "An informative error was not thrown." );
		</cfscript>
	</cffunction>

<!--- private --->
	<cffunction name="_getRunner" access="private" returntype="any" output="false">
		<cfargument name="logger" type="any" required="true" />

		<cfscript>
			return new preside.system.services.database.SqlRunner( logger = arguments.logger );
		</cfscript>
	</cffunction>

</cfcomponent>