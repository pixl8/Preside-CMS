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
				super.assertEquals( "The value of the param, [some_value], was not of a simple type", e.detail );
				errorThrown = true;
			}

			super.assert( errorThrown, "An informative error was not thrown." );
		</cfscript>
	</cffunction>

	<cffunction name="test04_runSql_shouldReturnArray_whenReturnTypeArray_passed" access="public" returntype="any" output="false">
		<cfscript>
			var logger = new tests.resources.HelperObjects.TestLogger( logLevel = "INFORMATION" );
			var runner = _getRunner( logger );
			var sqlStatements = [
				  "create table some_table ( some_table_id int )"
				, "insert into some_table values ( 1 ), ( 2 ), ( 3 )"
			];
			for( sql in sqlStatements ) {
				runner.runSql( dsn = application.dsn, sql = sql );
			}

			var result = runner.runSql(
				  dsn        = application.dsn
				, sql        = "select some_table_id from some_table order by some_table_id"
				, returntype = "array"
			)
			runner.runSql( dsn = application.dsn, sql = "drop table some_table" );

			super.assertEquals( [ { some_table_id=1 }, { some_table_id=2 }, { some_table_id=3 } ], result );
		</cfscript>
	</cffunction>

	<cffunction name="test04_runSql_shouldReturnStruct_whenReturnTypeStruct_passedWithColumnKey" access="public" returntype="any" output="false">
		<cfscript>
			var logger = new tests.resources.HelperObjects.TestLogger( logLevel = "INFORMATION" );
			var runner = _getRunner( logger );
			var sqlStatements = [
				  "create table some_table ( some_table_id int, label varchar(10) )"
				, "insert into some_table values ( 1, 'one' ), ( 2, 'two' ), ( 3, 'three' )"
			];
			for( sql in sqlStatements ) {
				runner.runSql( dsn = application.dsn, sql = sql );
			}

			var result = runner.runSql(
				  dsn        = application.dsn
				, sql        = "select some_table_id,label from some_table order by some_table_id"
				, returntype = "struct"
				, columnKey  = "label"
			)
			runner.runSql( dsn = application.dsn, sql = "drop table some_table" );

			super.assertEquals( { one={ some_table_id=1, label="one" }, two={ some_table_id=2, label="two" }, three={ some_table_id=3, label="three" } }, result );
		</cfscript>
	</cffunction>

	<cffunction name="test05_runSql_shouldMakeUseOfPassedTimeout" access="public" returntype="any" output="false">
		<cfscript>
			var logger = new tests.resources.HelperObjects.TestLogger( logLevel = "INFORMATION" );
			var runner = _getRunner( logger );
			var correctError = false;
			var start = getTickCount();

			try {
				runner.runSql( dsn=application.dsn, sql="select sleep( 10 )", timeout=1 );
			} catch( database e ) {
				correctError = ( e.message?: "" ) contains "timeout"
			}

			super.assert( correctError );
			super.assert( getTickCount()-start < 3000 );
		</cfscript>
	</cffunction>

	<cffunction name="test06_runSql_shouldMakeUseOfDefaultTimeout" access="public" returntype="any" output="false">
		<cfscript>
			var logger = new tests.resources.HelperObjects.TestLogger( logLevel = "INFORMATION" );
			var runner = _getRunner( logger=logger, defaultTimeout=1 );
			var correctError = false;
			var start = getTickCount();

			try {
				runner.runSql( dsn=application.dsn, sql="select sleep( 10 )" );
			} catch( database e ) {
				correctError = ( e.message?: "" ) contains "timeout"
			}

			super.assert( correctError );
			super.assert( getTickCount()-start < 3000 );
		</cfscript>
	</cffunction>



<!--- private --->
	<cffunction name="_getRunner" access="private" returntype="any" output="false">
		<cfargument name="logger"         type="any"     required="true" />
		<cfargument name="defaultTimeout" type="numeric" required="false" default="0" />

		<cfscript>
			return new preside.system.services.database.SqlRunner(
				  logger                = arguments.logger
				, defaultQueryTimeout   = arguments.defaultTimeout
				, defaultBgQueryTimeout = arguments.defaultTimeout
			);
		</cfscript>
	</cffunction>

</cfcomponent>