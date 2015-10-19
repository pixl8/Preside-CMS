<!---
	Project: SQLiteCFC
	Version: 1.1.1
	Creator: Shawn Grigson
			 shawn@grigson.org
			 
	Last Updated: 02/09/2010
	
	Developed originally for ArcStone Technologies 
	http://www.arcstone.com
	
	--------------------------------------------------------------------------------------------
	Example Usage:
	
	<cfscript>
		// normally you would probably want this to be instantiated into the application or even server scope as a singleton
		// tempdir: where SQLite files are written/located.
		// libdir: the 'lib' subfolder where base.db and sqlitejdbc.jar are located
		// model_path: (used for Javaloader) the cf-mappable location where this component lives.  ie., '/myApp/SqliteCFC'
		// dot_model_path: (used for Javaloader) the dot-mapping version of model_path.  ie., 'myApp.SqliteCFC'
		sqlite = CreateObject('component','SqliteCFC').init(
			tempdir = "#ExpandPath('temp/')#",
			libdir = "#ExpandPath('lib')#",
			model_path = "/app/SqliteCFC",
			dot_model_path = "app.SqliteCFC"
		);
		
		dbFile = sqlite.createDB('MyDB');
		conn = sqlite.convertQueryToTable(srcQuery=myQuery,dbFile=dbFile,table_name="newTable",closeConnection=false);
		
		// reuse the same connection, create a cfquery
		getQuery = sqlite.executeSql(dbFile,"select * from newTable",false,conn);
		
		// close the connection
		conn.close();
	</cfscript>
	--------------------------------------------------------------------------------------------
--->
<cfcomponent hint="Creates Sqlite dbs, converts CF recordsets to SQLite tables and CSV files, reads CSV files and converts them to cf queries or read and write directly to a SQLite table" output="false">
	
	<cffunction name="init" access="public" returntype="SqliteCFC" output="false">
		<cfargument name="tempdir" type="string" required="false" default="" hint="Where temporary files get written, incuding trailing slash" />
		<cfargument name="libdir" type="string" required="false" default="" hint="Where the base.db is located, so it can be copied"/>
		<cfargument name="model_path" type="string" required="false" default="" hint="change this to match your environment" />
		<cfargument name="dot_model_path" type="string" required="false" default="" hint="change this to match model_path, but it must be dot-delimited" />
		
		<cfset variables.tempDir = arguments.tempdir />
		<cfset variables.libDir = arguments.libdir />
		
		<!--- These variables might need to change to match your local environment. ONLY used by the Javaloader, if you have sqlitejdbc.jar registered on your CF server, you need pass nothing for these. --->
		<cfset variables.model_path = arguments.model_path />
		<cfset variables.dot_model_path = arguments.dot_model_path />
		
		<!--- CSV-parsing regex
			Get the regular expression to match the tokens.
			
			Thank you, Ben Nadel: http://www.bennadel.com/index.cfm?dax=blog:976.view
		--->
		<cfset variables.strRegEx = (
			"(""(?:[^""]|"""")*""|[^"",\r\n]*)(,|\r\n?|\n)?"
			)/>
			
		<!---
			Create a compiled Java regular expression pattern object
			based on the pattern above.
		--->
		<cfset variables.objPattern = CreateObject(
			"java",
			"java.util.regex.Pattern"
			).Compile(
				JavaCast( "string", variables.strRegEx )
				)
			/>
		
		<cfreturn this />
	</cffunction>
	
	<!--- Private Methods --->
	<cffunction name="getJavaLoader" access="private" returntype="any" output="false">
		<cfset var paths = ArrayNew(1) />
		
		<cfif NOT StructKeyExists(variables,"loader")>
			<cfset paths[1] = expandPath("#variables.model_path#/lib/sqlite-jdbc-3.7.2.jar") />
			<cfset variables.loader = createObject("component", "#variables.dot_model_path#.lib.javaloader.JavaLoader").init(paths) />
		</cfif>
		
		<cfreturn variables.loader />
	</cffunction>
	<cffunction name="getDriver" access="private" returntype="any" output="false">
		
		<cfif NOT StructKeyExists(variables,"driver")>
			<cftry>
				<cfset variables.driver = createObject( 'java', 'org.sqlite.JDBC' ).init() />
				<cfcatch type="any">
					<cfset variables.driver = getJavaLoader().create("org.sqlite.JDBC").init() />
				</cfcatch>
			</cftry>
		</cfif>
		
		<cfreturn variables.driver />
	</cffunction>
	<cffunction name="getProperties" access="private" returntype="any" output="false">
		<cfif NOT StructKeyExists(variables,"properties")>
			<cfset variables.properties = createObject( 'java', 'java.util.Properties').init() />
		</cfif>
		
		<cfreturn variables.properties />
	</cffunction>
	<cffunction name="getDriverManager" access="private" returntype="any" output="false">
		<cfreturn CreateObject('java','java.sql.DriverManager') />
	</cffunction>
	<cffunction name="getConnection" access="public" returntype="any" output="false" hint="connects directly to a Sqlite DB and returns a jdbc connection object">
		<cfargument name="dbFile" type="string" required="true" />
		
		<cfscript>
			var props = getProperties();
			var conn = getDriver().connect('jdbc:sqlite:' & arguments.dbFile, props);
			
			return conn;
		</cfscript>
	</cffunction>
	
	<cffunction name="getStringBuilder" access="public" returntype="any" output="false">
		<!--- StringBuilder cannot be a singleton as this may occur across multiple requests --->
		<cftry>
			<!--- Need a try/catch.  StringBuilder might not exist on the server (prior to Java 1.5) so this will use StringBuffer if there's a failure with StringBuilder --->
			<cfreturn createObject("java", "java.lang.StringBuilder").init() />
			<cfcatch type="any">
				<cfreturn createObject("java", "java.lang.StringBuffer").init() />
			</cfcatch>
		</cftry>
	</cffunction>
	
	
	<!--- Public Methods --->
	<cffunction name="getDBFilePath" access="public" returntype="string" output="false" hint="takes a db name (minus the extension) and returns the path to the file">
		<cfargument name="dbName" type="string" required="true" />
		<cfargument name="destDir" type="string" required="false" default="#variables.tempDir#" />
		
		<cfreturn "#arguments.destDir##arguments.dbName#.db" />
	</cffunction>
	
	<cffunction name="createDB" access="public" returntype="string" output="false" hint="creates a dbname.db file.  We do a file copy rather than a cfexecute for permission purposes, then return the full path to the db">
		<cfargument name="dbName" type="string" required="true" />
		<cfargument name="destDir" type="string" required="false" default="#variables.tempDir#" />
		
		<cffile action="copy" source="#variables.libDir#base.db" destination="#getDBFilePath(argumentCollection=arguments)#" mode="644" nameconflict="overwrite" /> 
		<cfreturn getDBFilePath(argumentCollection=arguments) />
	</cffunction>
	<cffunction name="renameDB" access="public" returntype="string" output="false" hint="creates a dbname.db file.  We do a file copy rather than a cfexecute for permission purposes, then return the full path to the db">
		<cfargument name="dbName" type="string" required="true" />
		<cfargument name="newDbName" type="string" required="true" />
		<cfargument name="destDir" type="string" required="false" default="#variables.tempDir#" />
		
		<cffile action="rename" source="#getDBFilePath(argumentCollection=arguments)#" destination="#arguments.destDir##arguments.newDbName#.db" mode="644" /> 
		<cfreturn getDBFilePath(argumentCollection=arguments) />
	</cffunction>
	<cffunction name="deleteDB" access="public" returntype="string" output="false" hint="creates a dbname.db file.  We do a file copy rather than a cfexecute for permission purposes, then return the full path to the db">
		<cfargument name="dbName" type="string" required="true" />
		<cfargument name="destDir" type="string" required="false" default="#variables.tempDir#" />
		
		<cffile action="delete" file="#getDBFilePath(argumentCollection=arguments)#" /> 
		<cfreturn getDBFilePath(argumentCollection=arguments) />
	</cffunction>
	
	<cffunction name="createTable" access="public" output="true" returntype="any" hint="creates a table in the destination Sqlite dbFile, uses columnlist to create a series of fields, all with the 'text' datatype">
		<cfargument name="dbFile" type="string" required="true" hint="The full path to the Sqlite db file" />
		<cfargument name="table_name" type="string" required="true" />
		<cfargument name="columnlist" type="string" required="true" />
		<cfargument name="dropExisting" type="boolean" required="false" default="true" />
		<cfargument name="closeConnection" type="boolean" required="false" default="true" />
		<cfargument name="connection" type="any" required="false" hint="if supplied, will reuse this connection rather than opening a new one" />
		<cfargument name="primary_columns" type="string" required="false" default="" hint="a list of primary keys for this table" />
		<cfargument name="numeric_columns" type="string" required="false" default="" hint="columns which should be declared as numeric" />
		<cfargument name="index_columns" type="string" required="false" default="" hint="a list of columns to be indexed" />
		<cfargument name="unique_index_columns" type="string" required="false" default="" hint="a list of columns to receive a unique index" />
		
		
		<cfset var columns = "" />
		<cfset var col = "" />
		<cfset var conn = "" />
		<cfset var multiPrimary = false />
		
		<cfif StructKeyExists(arguments,"connection")>
			<cfset conn = arguments.connection />
		<cfelse>
			<cfset conn = getConnection(arguments.dbFile) />
		</cfif>
		
		<cftry>
			<cfloop list="#arguments.columnlist#" index="col">
				<cfif ListFindNoCase(arguments.primary_columns,col)>
					<cfif ListLen(arguments.primary_columns) EQ 1>
						<cfset columns = ListAppend(columns,"'#lcase(col)#' INTEGER PRIMARY KEY ASC AUTOINCREMENT") />
					<cfelse>
						<cfset columns = ListAppend(columns,"'#lcase(col)#' INTEGER") />
						<cfset multiPrimary = true />
					</cfif>
				<cfelseif ListFindNoCase(arguments.numeric_columns,col)>
					<cfset columns = ListAppend(columns,"'#lcase(col)#' REAL") />
				<cfelse>
					<cfset columns = ListAppend(columns,"'#lcase(col)#' text") />
				</cfif>
			</cfloop>
			
			<cfif multiPrimary>
				<cfset columns = ListAppend(columns,"PRIMARY KEY(#arguments.primary_columns#)") />
			</cfif>
			
			<cfif arguments.dropExisting>
				<cfset executeSql(dbFile=arguments.dbFile,sql="DROP TABLE IF EXISTS #arguments.table_name#;",closeConnection=false,connection=conn) />
			</cfif>
			
			<cfset executeSql(dbFile=arguments.dbFile,sql="CREATE TABLE IF NOT EXISTS #arguments.table_name# (#columns#);",closeConnection=false,connection=conn) />
			
			<cfif arguments.closeConnection>
				<cfset conn.close() />
			</cfif>
			
			<cfcatch type="any">
				<!--- In case of an error, close the connection --->
				<cfset conn.close() />
				<cfthrow 
					type="SQLiteCFC.createTable.syntaxError" 
					message="#cfcatch.message#">
			</cfcatch>
		</cftry>
		
		<cfreturn conn />
	</cffunction>
	
	<cffunction name="executeSql" access="public" returntype="any" output="true" hint="executes sqlite commands, returns a CF query for a select, and a connection object for all other statements">
		<cfargument name="dbFile" type="string" required="true" hint="The full path to the Sqlite db file" />
		<cfargument name="sql" type="string" required="true" />
		<cfargument name="closeConnection" type="boolean" required="false" default="true" />
		<cfargument name="connection" type="any" required="false" hint="if supplied, will reuse this connection rather than opening a new one" />
		
		<cfset var output = "" />	
		<cfset var conn = "" />
		<cfset var stat = "" />
		<cfset var query = "" />
		<cfset var rs = "" />
		<cfset var queryTable = "" />
		
		<cfif StructKeyExists(arguments,"connection")>
			<cfset conn = arguments.connection />
		<cfelse>
			<cfset conn = getConnection(arguments.dbFile) />
		</cfif>
		
		<cftry>
			<cfset stat = conn.createStatement() />
			
			<cfif Left(trim(arguments.sql),6) EQ "SELECT">
				<cfset rs = stat.executeQuery(trim(arguments.sql)) />
				
				<!--- convert this Java resultset to a CF query recordset --->
				<cfif SERVER.coldfusion.ProductName EQ "Railo">
					<cfset queryTable = CreateObject("java", "railo.runtime.type.QueryImpl") />
					<cfset query = queryTable.init(rs,"queryTable") />
				<cfelse>
					<cfset queryTable = CreateObject("java", "coldfusion.sql.QueryTable")>
					<cfset queryTable.init(rs) >
					<cfset query = queryTable.FirstTable() />
				</cfif>
				<cfset rs.close() />
				
				<cfif arguments.closeConnection>
					<cfset conn.close() />
				</cfif>
				<cfreturn query />
			<cfelse>
				<!--- <cfset WriteOutput(arguments.sql) /> --->
				<cfset query = stat.executeUpdate(arguments.sql) />
				<cfif arguments.closeConnection>
					<cfset conn.close() />
				</cfif>
				<cfreturn conn />
			</cfif>
			<cfcatch type="any">
				<!--- Make sure the connection gets closed if there is an error, otherwise a memory leak can occur --->
				<cfset conn.close() />
				<cfthrow 
					object="#cfcatch#">
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="convertQueryToCSV" access="public" returntype="string" output="false" hint="dumps a CF query to a CSV file">
		<cfargument name="srcQuery" type="query" required="true" />
		<cfargument name="fileName" type="string" required="false" default="#CreateUUID()#file.csv" hint="The name of the file to be created" />
		<cfargument name="destDir" type="string" required="false" default="#variables.tempDir#" />
		<cfargument name="delimiter" type="string" required="false" default=","/>
		<cfargument name="quoted" type="boolean" required="false" default="true" hint="whether or not to quote the values in the file" />
		<cfargument name="include_column_headers" type="boolean" required="false" default="false" hint="whether or not to render the columnlist as the first line of the CSV" />
		<cfargument name="bufferOnly" type="boolean" required="false" default="false" hint="if true, don't write a file.  Just return the file content" />
		
		<cfscript>
			var i = 0;
			var j = 0;
			var ch = arguments.delimiter;
			var firstPos = 1;
			var col = "";
			var columnlist = arguments.srcQuery.columnList;
			var stringBuilder = getStringBuilder();
			var crlf = CHR(10);
			var theValue = "";
			
			if (arguments.include_column_headers) {
				for (j=1;j LTE ListLen(columnlist);j=j+1) {
					col = ListGetAt(columnlist,j);
					
					if (firstPos) {
						firstPos = 0;
					} else {
						stringBuilder.append(ch);
					}
					
					if (arguments.quoted) {
						stringBuilder.append("""#col#""");
					} else {
						stringBuilder.append(col);
					}
				}
				
				// add newline character
				stringBuilder.append(crlf);
			}
			
			for (i=1;i LTE arguments.srcQuery.recordcount;i=i+1) {
				firstPos = 1; // this is the first column
				theLine = "";
				
				for (j=1;j LTE ListLen(columnlist);j=j+1) {
					col = ListGetAt(columnlist,j);
					theValue = arguments.srcQuery[col][i];
					
					// format date
					if (isDate(theValue) AND Len(trim(theValue)) GTE 8) {
						theValue = DateFormat(theValue,"yyyy-mm-dd") & " " & TimeFormat(theValue,"HH:mm:ss");
					}
					
					if (firstPos) {
						firstPos = 0;
					} else {
						stringBuilder.append(ch);
					}
					
					if (arguments.quoted) {
						stringBuilder.append("""#theValue#""");
					} else {
						stringBuilder.append(theValue);
					}
				}
				
				// newline character
				stringBuilder.append(crlf);
			}
		</cfscript>
		
		<cfif arguments.bufferOnly>
			<cfreturn stringBuilder.toString() />
		<cfelse>
			<cffile action="write" file="#arguments.destDir##arguments.fileName#" mode="644" nameconflict="overwrite" output="#stringBuilder.toString()#" /> 	
			<cfreturn "#arguments.destDir##arguments.fileName#" />
		</cfif>
	</cffunction>
	
	<cffunction name="convertQueryToTable" access="public" returntype="any" output="true" hint="dumps a CF query to a Sqlite table">
		<cfargument name="srcQuery" type="query" required="true" />
		<cfargument name="dbFile" type="string" required="true" />
		<cfargument name="table_name" type="string" required="true" />
		<cfargument name="primary_columns" type="string" required="false" default="" hint="a list of primary keys for this table" />
		<cfargument name="numeric_columns" type="string" required="false" default="" hint="columns which should be declared as numeric" />
		<cfargument name="index_columns" type="string" required="false" default="" hint="a list of columns to be indexed" />
		<cfargument name="unique_index_columns" type="string" required="false" default="" hint="a list of columns to receive a unique index" />
		<cfargument name="dropExisting" type="boolean" required="false" default="true"/>
		<cfargument name="closeConnection" type="boolean" required="false" default="true" />
		<cfargument name="connection" type="any" required="false" hint="if supplied, will reuse this connection rather than opening a new one" />
		<cfargument name="columns" type="string" required="false" default="" hint="alternate list of column names" />
		
		<cfscript>
			var i = 0;
			var j = 0;
			var col = "";
			var columnlist = "";
			var conn = "";
			var prep = "";
			var fillers = "?";
			var theValue = "";
			var iColumnlist = arguments.srcQuery.columnList; // internal column list for reference.  The passed query might have different column names from the list of columns provided as a mapping.
			
			if (NOT Len(trim(arguments.columns))) {
				columnlist = iColumnlist;
			} else {
				columnlist = arguments.columns;
			}
			
			if (ListLen(columnlist) GT 1) {
				fillers = fillers & RepeatString(",?",ListLen(columnlist) - 1);
			}
			
			if (StructKeyExists(arguments,"connection")) {
				conn = arguments.connection;
				conn = createTable(dbFile=arguments.dbFile,table_name=arguments.table_name,columnlist=columnlist,dropExisting=arguments.dropExisting,closeConnection=false,connection=conn,primary_columns=arguments.primary_columns,numeric_columns=arguments.numeric_columns,index_columns=arguments.index_columns,unique_index_columns=arguments.unique_index_columns);
			}
			else { 
				conn = createTable(dbFile=arguments.dbFile,table_name=arguments.table_name,columnlist=columnlist,dropExisting=arguments.dropExisting,closeConnection=false,primary_columns=arguments.primary_columns,numeric_columns=arguments.numeric_columns,index_columns=arguments.index_columns,unique_index_columns=arguments.unique_index_columns);
			}
			
			try {
				// create the prepared statement
				prep = conn.prepareStatement("insert into #arguments.table_name# values (#fillers#);");
				
				// loop over rows and columns, and set all batch positions
				for (i=1;i LTE arguments.srcQuery.recordcount;i=i+1) {
					for (j=1;j LTE ListLen(columnlist);j=j+1) {
						col = ListGetAt(iColumnlist,j);
						theValue = arguments.srcQuery[col][i];
						
						// format date
						if (isDate(theValue) AND Len(trim(theValue)) GTE 8) {
							theValue = DateFormat(theValue,"yyyy-mm-dd") & " " & TimeFormat(theValue,"HH:mm:ss");
						}
						// replace of double quotes should not be necessary
					//	prep.setString(JavaCast('int',j), Replace(arguments.srcQuery[col][i],"""","'","ALL"));
						prep.setString(JavaCast('int',j), JavaCast('string',theValue));
					}
					
					prep.addBatch();
				}
				
				conn.setAutoCommit(false);
		    	prep.executeBatch();
		    	conn.setAutoCommit(true);
				
				if (arguments.closeConnection) {
					conn.close();
				}
			} catch (any excpt) {
				// be sure to close the connection if an error occurs, to prevent a memory leak
				conn.close();	
				WriteOutput("Error Occurred in convertQueryToTable: " & excpt.message);
			}
					
			return conn;
		</cfscript>
	</cffunction>
	
	
	
	<!---	
		SDG - Thank you, thank you, Ben Nadel, for your excellent help with parsing CSV files effectively using regex. 
	--->
	<!--- --------------------------------------------------------------------------------------- ----
	
	Blog Entry:
	Regular Expressions Make CSV Parsing In ColdFusion So Much Easier (And Faster)
	
	Code Snippet:
	1
	
	Author:
	Ben Nadel / Kinky Solutions
	
	Link:
	http://www.bennadel.com/index.cfm?dax=blog:976.view
	
	Date Posted:
	Sep 28, 2007 at 7:29 AM
	
	---- --------------------------------------------------------------------------------------- --->
	<cffunction name="convertCSVToArray" access="public" output="false" returntype="array" hint="reads a CSV file, converting it to an array. Borrowed heavily from Ben Nadel.">
		<cfargument name="fileName" type="string" required="true" hint="filename to be read" />
		
		<cfset var strCSV = "" />
		<cfset var objMatcher = "" />
		<cfset var arrData = ArrayNew(1) />
		<cfset var instance = StructNew() />
		
		<cffile action="read" file="#arguments.fileName#" variable="strCSV" />
		
		<!--- Trim data values. --->
		<cfset strCSV = Trim( strCSV ) />
		 
		<!---
			Get the pattern matcher for our target text (the CSV data).
			This will allows us to iterate over all the data fields.
		--->
		<cfset objMatcher = variables.objPattern.Matcher(
			JavaCast( "string", strCSV )
			) />
		 
		 
		<!---
			We are going
			to create an array of arrays in which each nested
			array represents a row in the CSV data file.
		--->
		 
		<!--- Start off with a new array for the new data. --->
		<cfset ArrayAppend( arrData, ArrayNew( 1 ) ) />
		 
		 
		<!---
			Here's where the magic is taking place; we are going
			to use the Java pattern matcher to iterate over each
			of the CSV data fields using the regular expression
			we defined above.
		 
			Each match will have at least the field value and
			possibly an optional trailing delimiter.
		--->
		<cfloop condition="objMatcher.Find()">
		 
			<!--- Get the field token value. --->
			<cfset instance.Value = objMatcher.Group(
				JavaCast( "int", 1 )
				) />
		 
			<!--- Remove the field qualifiers (if any). --->
			<cfset instance.Value = instance.Value.ReplaceAll(
				JavaCast( "string", "^""|""$" ),
				JavaCast( "string", "" )
				) />
		 
			<!--- Unesacepe embedded qualifiers (if any). --->
			<cfset instance.Value = instance.Value.ReplaceAll(
				JavaCast( "string", "(""){2}" ),
				JavaCast( "string", "$1" )
				) />
		 
			<!--- Add the field value to the row array. --->
			<cfset ArrayAppend(
				arrData[ ArrayLen( arrData ) ],
				instance.Value
				) />
		 
		 
			<!---
				Get the delimiter. If no delimiter group was matched,
				this will destroy the variable in the instance scope.
			--->
			<cfset instance.Delimiter = objMatcher.Group(
				JavaCast( "int", 2 )
				) />
		 
		 
			<!--- Check for delimiter. --->
			<cfif StructKeyExists( instance, "Delimiter" )>
		 
				<!---
					Check to see if we need to start a new array to
					hold the next row of data. We need to do this if the
					delimiter we just found is NOT a field delimiter.
				--->
				<cfif (instance.Delimiter NEQ ",")>
		 
					<!--- Start new row data array. --->
					<cfset ArrayAppend(
						arrData,
						ArrayNew( 1 )
						) />
		 
				</cfif>
		 
			<cfelse>
		 
				<!---
					If there is no delimiter, then we are done parsing
					the CSV file data. Break out rather than just ending
					the loop to make sure we don't get any extra data.
				--->
				<cfbreak />
		 
			</cfif>
		 
		</cfloop>
		 
		 
		<!--- Dump out CSV data array. --->
		<cfreturn arrData />
	</cffunction>
	
	<!--- <cffunction name="convertArrayToQuery" access="public" output="false" returntype="query" hint="takes and array and a columnlist, turns it into a query">
		<cfargument name="srcArray" type="array" required="true" />
		<cfargument name="first_row_as_columns" type="boolean" required="false" default="true" hint="expects first row of an array as having the columns" />
		<cfargument name="columnlist" type="string" default="" required="false" hint="the list of columns, if first_row_as_header is false" />
		<cfargument name="ignore_columns" type="string" required="false" default="" hint="some columns are junk columns. this is a comma-separated list of the column names, not position numbers, to be ignored" />
		
		<cfscript>
			var query = "";
			var cols = "";
			var i = 1; // rows
			var j = 1; // columns
			var c = 1;
			
			// ignore the first row if we're reading the columns
			if (arguments.first_row_as_columns) {
				for (c = 1;c LTE ArrayLen(arguments.srcArray[1]);c = c + 1) {
					cols = ListAppend(cols,arguments.srcArray[1][c]);
				}
				i = 2; // start looping from the second row	
			} else {
				cols = arguments.columnlist;	
			}
			
			query = queryNew(cols);
			
			// I hate pre-cf8 for loop syntax
			for (i = i;i LTE ArrayLen(arguments.srcArray);i = i + 1) {
				queryAddRow(query);
				
				for (j=1;j LTE ListLen(cols);j = j+1) {
					querySetCell(query, ListGetAt(cols,j), arguments.srcArray[i][j]);	
				}
			}
			
			return query;
		</cfscript>		
	</cffunction> --->
	
	<cffunction name="convertCSVToQuery" access="public" output="false" returntype="query" hint="reads a CSV file, converting it to a query. Borrowed heavily from Ben Nadel.">
		<cfargument name="fileName" type="string" required="true" hint="filename to be read" />
		<cfargument name="first_row_as_columns" type="boolean" required="false" default="true" hint="expects first row of a CSV as having the columns" />
		<cfargument name="columnlist" type="string" required="false" default="" hint="the list of columns, if first_row_as_header is false" />
		<cfargument name="ignore_columns" type="string" required="false" default="" hint="some columns are junk columns. this is a comma-separated list of the column names, not position numbers, to be ignored" />
		
		<cfscript>
			var i = 0;
			var j = 0;
			var col = 1;
			var columns = arguments.columnlist;
			var strCSV = "";
			var objMatcher = "";
			var instance = StructNew();
			var query = "";
		</cfscript>
		
		<cffile action="read" file="#arguments.fileName#" variable="strCSV" />
		
		<cfscript>
			strCSV = Trim( strCSV );
			objMatcher = variables.objPattern.Matcher(JavaCast( "string", strCSV ));
			
			// Call the first row and iterate over it, setting the columnlist
			if (arguments.first_row_as_columns) {
				
				while (objMatcher.Find()) {
					instance.Value = objMatcher.Group(JavaCast( "int", 1 ));
				 
					// Remove the field qualifiers (if any).
					instance.Value = instance.Value.ReplaceAll(JavaCast( "string", "^""|""$" ), JavaCast( "string", "" ));
				 
					// Unesacepe embedded qualifiers (if any).
					instance.Value = instance.Value.ReplaceAll(JavaCast( "string", "(""){2}" ),	JavaCast( "string", "$1" ));
					
					// remove all spaces, for columns.  Spaces in column names are stupid
					instance.Value = Replace(instance.Value.toString()," ","","ALL");
					
					columns = ListAppend(columns,instance.Value);
					/*
						Get the delimiter. If no delimiter group was matched,
						this will destroy the variable in the instance scope.
					*/
					instance.Delimiter = objMatcher.Group(JavaCast( "int", 2 ));
				 
					// Check for delimiter.
					if (StructKeyExists( instance, "Delimiter" )) {
				 
						/*
							Check to see if we need to break out of the loop
						*/
						if (instance.Delimiter NEQ ",") {
				 			
				 			// Start new row data array
				 			break;
						}
				 
					}
					
				}
			}
			
			// create the new query object, passing the columns in as the columnlist
			query = queryNew(columns);
		
	 		// add a new row to the query
	 		queryAddRow(query);
			
			// loop over rows and columns, and set all batch positions
		 	while (objMatcher.Find()) {
		 		instance.Value = objMatcher.Group(JavaCast( "int", 1 ));
			 
				// Remove the field qualifiers (if any).
				instance.Value = instance.Value.ReplaceAll(JavaCast( "string", "^""|""$" ), JavaCast( "string", "" ));
			 
				// Unesacepe embedded qualifiers (if any).
				instance.Value = instance.Value.ReplaceAll(JavaCast( "string", "(""){2}" ),	JavaCast( "string", "$1" ));
				
				// set this cell of the query
				querySetCell(query, ListGetAt(columns,col), instance.Value);	
			 
				/*
					Get the delimiter. If no delimiter group was matched,
					this will destroy the variable in the instance scope.
				*/
				instance.Delimiter = objMatcher.Group(JavaCast( "int", 2 ));
			 
				// Check for delimiter.
				if (StructKeyExists( instance, "Delimiter" )) {
			 
					/*
						Check to see if we need to add this as a batch to
						hold the next row of data. We need to do this if the
						delimiter we just found is NOT a field delimiter.
					*/
					if (instance.Delimiter NEQ ",") {
			 			
			 			// Start new query row
			 			queryAddRow(query);
						
			 			// reset col
			 			col = 0;
					}
			 
				} else {
			 
					/*
						If there is no delimiter, then we are done parsing
						the CSV file data. Break out rather than just ending
						the loop to make sure we don't get any extra data.
					*/
					break;
			 
				}
			 	
			 	col = col + 1;
			}
			
			return query;
		</cfscript>
	</cffunction>
	
	<!--- Read/Writes a CSV directly to a SQLite table via prepared statement.  Cuts out the middleman. --->
	<cffunction name="convertCSVToTable" access="public" output="false" returntype="any" hint="reads a CSV file, converting it to a sqlite table. Inspired by Ben Nadel's csv-parsing regex.">
		<cfargument name="fileName" type="string" required="true" hint="filename to be read" />
		<cfargument name="dbFile" type="string" required="true" />
		<cfargument name="table_name" type="string" required="true" />
		<cfargument name="primary_columns" type="string" required="false" default="" hint="a list of primary keys for this table" />
		<cfargument name="numeric_columns" type="string" required="false" default="" hint="columns which should be declared as numeric" />
		<cfargument name="index_columns" type="string" required="false" default="" hint="a list of columns to be indexed" />
		<cfargument name="first_row_as_columns" type="boolean" required="false" default="true" hint="expects first row of a CSV as having the columns" />
		<cfargument name="columnlist" type="string" required="false" default="" hint="the list of columns, if first_row_as_header is false" />
		<cfargument name="ignore_columns" type="string" required="false" default="" hint="some columns are junk columns. this is a comma-separated list of the column names, not position numbers, to be ignored" />
		<cfargument name="unique_index_columns" type="string" required="false" default="" hint="a list of columns to receive a unique index" />
		<cfargument name="dropExisting" type="boolean" required="false" default="true"/>
		<cfargument name="closeConnection" type="boolean" required="false" default="true" />
		<cfargument name="connection" type="any" required="false" hint="if supplied, will reuse this connection rather than opening a new one" />
		

		<cfscript>
			var i = 0;
			var j = 0;
			var col = 1;
			var columns = arguments.columnlist;
			var conn = "";
			var prep = "";
			var fillers = "?";
			var strCSV = "";
			var objMatcher = "";
			var instance = StructNew();
		</cfscript>
		
		<cffile action="read" file="#arguments.fileName#" variable="strCSV" />
		
		<cfscript>
			strCSV = Trim( strCSV );
			objMatcher = variables.objPattern.Matcher(JavaCast( "string", strCSV ));
			
			// Call the first row and iterate over it, setting the columnlist
			if (arguments.first_row_as_columns) {
				
				while (objMatcher.Find()) {
					instance.Value = objMatcher.Group(JavaCast( "int", 1 ));
				 
					// Remove the field qualifiers (if any).
					instance.Value = instance.Value.ReplaceAll(JavaCast( "string", "^""|""$" ), JavaCast( "string", "" ));
				 
					// Unesacepe embedded qualifiers (if any).
					instance.Value = instance.Value.ReplaceAll(JavaCast( "string", "(""){2}" ),	JavaCast( "string", "$1" ));
					
					// remove all spaces, for columns.  Spaces in column names are stupid
					instance.Value = Replace(instance.Value.toString()," ","","ALL");
					
					columns = ListAppend(columns,instance.Value);
					/*
						Get the delimiter. If no delimiter group was matched,
						this will destroy the variable in the instance scope.
					*/
					instance.Delimiter = objMatcher.Group(JavaCast( "int", 2 ));
				 
					// Check for delimiter.
					if (StructKeyExists( instance, "Delimiter" )) {
				 
						/*
							Check to see if we need to break out of the loop
						*/
						if (instance.Delimiter NEQ ",") {
				 			
				 			// Start new row data array
				 			break;
						}
				 
					}
					
				}
			}
			
			if (ListLen(columns) GT 1) {
				fillers = fillers & RepeatString(",?",ListLen(columns) - 1);
			}
			
			if (StructKeyExists(arguments,"connection")) {
				conn = arguments.connection;
				conn = createTable(dbFile=arguments.dbFile,table_name=arguments.table_name,columnlist=columns,dropExisting=arguments.dropExisting,closeConnection=false,connection=conn,primary_columns=arguments.primary_columns,numeric_columns=arguments.numeric_columns,index_columns=arguments.index_columns,unique_index_columns=arguments.unique_index_columns);
			}
			else { 
				conn = createTable(dbFile=arguments.dbFile,table_name=arguments.table_name,columnlist=columns,dropExisting=arguments.dropExisting,closeConnection=false,primary_columns=arguments.primary_columns,numeric_columns=arguments.numeric_columns,index_columns=arguments.index_columns,unique_index_columns=arguments.unique_index_columns);
			}
			
			
		 	try {
				// create the prepared statement
				prep = conn.prepareStatement("insert into #arguments.table_name# values (#fillers#);");
				
				// loop over rows and columns, and set all batch positions
			 	while (objMatcher.Find()) {
			 		instance.Value = objMatcher.Group(JavaCast( "int", 1 ));
				 
					// Remove the field qualifiers (if any).
					instance.Value = instance.Value.ReplaceAll(JavaCast( "string", "^""|""$" ), JavaCast( "string", "" ));
				 
					// Unesacepe embedded qualifiers (if any).
					instance.Value = instance.Value.ReplaceAll(JavaCast( "string", "(""){2}" ),	JavaCast( "string", "$1" ));
					
					// populate this row of the batch with this column value
					prep.setString(JavaCast('int',col), JavaCast('string',instance.Value));
				 
					/*
						Get the delimiter. If no delimiter group was matched,
						this will destroy the variable in the instance scope.
					*/
					instance.Delimiter = objMatcher.Group(JavaCast( "int", 2 ));
				 
					// Check for delimiter.
					if (StructKeyExists( instance, "Delimiter" )) {
				 
						/*
							Check to see if we need to add this as a batch to
							hold the next row of data. We need to do this if the
							delimiter we just found is NOT a field delimiter.
						*/
						if (instance.Delimiter NEQ ",") {
				 			
				 			// Start new row data array
				 			prep.addBatch();
							
				 			// reset col
				 			col = 0;
						}
				 
					} else {
				 
						/*
							If there is no delimiter, then we are done parsing
							the CSV file data. Break out rather than just ending
							the loop to make sure we don't get any extra data.
						*/
						break;
				 
					}
				 	
				 	col = col + 1;
				}
				
				conn.setAutoCommit(false);
		    	prep.executeBatch();
		    	conn.setAutoCommit(true);
				
				if (arguments.closeConnection) {
					conn.close();
				}
			} catch (any excpt) {
				// be sure to close the connection if an error occurs, to prevent a memory leak
				conn.close();	
				WriteOutput("Error Occurred in convertCSVToTable: " & excpt.message);
			}
			
			return conn;
		</cfscript>
	</cffunction>

</cfcomponent>