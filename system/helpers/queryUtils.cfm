<cffunction name="queryRowToStruct" access="public" returntype="struct" output="false">
	<cfargument name="qry" type="query"   required="true" />
	<cfargument name="row" type="numeric" required="false" default="1" /><cfsilent>

	<cfscript>
		var strct = StructNew();
		var cols  = ListToArray( arguments.qry.columnList );
		var col   = "";

		for( col in cols ){
			strct[col] = arguments.qry[col][arguments.row];
		}

		return strct;
	</cfscript>
</cfsilent></cffunction>

<cffunction name="queryToArray" access="public" returntype="array" output="false">
	<cfargument name="qry"     type="query"  required="true" />
	<cfargument name="columns" type="string" required="false" default="#arguments.qry.columnList#" /><cfsilent>

	<cfscript>
		var arr    = ArrayNew(1);
		var cols   = ListToArray( arguments.columns );
		var row    = "";
		var col    = "";
		var record = "";

		for( row in arguments.qry ){
			record = StructNew();
			for( col in cols ){
				if ( StructKeyExists( row, col ) ) {
					record[col] = row[col];
				}
			}
			ArrayAppend( arr, record );
		}

		return arr;
	</cfscript>
</cfsilent></cffunction>

<cffunction name="arrayOfStructsToQuery" access="public" returntype="query" output="false">
	<cfargument name="columnList"     type="string" required="true" />
	<cfargument name="arrayOfStructs" type="array"  required="true" /><cfsilent>

	<cfscript>
		var q = QueryNew( arguments.columnList );

		for( var st in arguments.arrayOfStructs ){
			QueryAddRow( q, st );
		}

		return q;
	</cfscript>
</cfsilent></cffunction>

<cffunction name="obfuscateSqlForPreside" access="public" returntype="any" output="false"><cfsilent>
	<cfreturn getSingleton( "sqlRunner" ).obfuscateSqlForPreside( argumentCollection=arguments ) />
</cfsilent></cffunction>

<cffunction name="deObfuscateSql" access="public" returntype="any" output="false"><cfsilent>
	<cfreturn getSingleton( "sqlRunner" ).deObfuscateSql( argumentCollection=arguments ) />
</cfsilent></cffunction>
