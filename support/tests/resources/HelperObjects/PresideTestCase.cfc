<cfcomponent output="false" extends="mxunit.framework.TestCase" hint="An utility base class for our test cases">

<!--- private --->
	<cffunction name="_getCachebox" access="private" returntype="any" output="false">
		<cfscript>
			if ( !request.keyExists( "_cachebox" ) ) {
				request._cachebox = new coldbox.system.cache.CacheFactory( config="preside.system.config.Cachebox" );
			}

			return request._cachebox;
		</cfscript>
	</cffunction>

	<cffunction name="_getTestLogger" access="private" returntype="any" output="false">
		<cfargument name="logLevel" type="string" required="false" default="ERROR" />

		<cfreturn new tests.resources.HelperObjects.TestLogger( logLevel = arguments.logLevel ) />
	</cffunction>

	<cffunction name="_getBCrypt" access="private" returntype="any" output="false">
		<cfreturn new preside.system.api.encryption.bcrypt.BCryptService() />
	</cffunction>

	<cffunction name="_getPresideObjectService" access="private" returntype="any" output="false">
		<cfargument name="objectDirectories" type="array"   required="false" default="#ListToArray( '/preside/system/preside-objects' )#" />
		<cfargument name="defaultPrefix"     type="string"  required="false" default="pobj_" />
		<cfargument name="forceNewInstance"  type="boolean" required="false" default="false" />

		<cfscript>
			if ( arguments.forceNewInstance || !request.keyExists( "_presideObjectService" ) ) {
				var logger = _getTestLogger();
				var objReader = new preside.system.api.presideObjects.Reader(
					  dsn = application.dsn
					, tablePrefix = arguments.defaultPrefix
				);
				var cachebox       = _getCachebox();
				var dbInfoService  = new preside.system.api.database.Info();
				var sqlRunner      = new preside.system.api.database.sqlRunner( logger = logger );

				var adapterFactory = new preside.system.api.database.adapters.AdapterFactory(
					  cache         = cachebox.getCache( "SystemCache" )
					, dbInfoService = dbInfoService
				);
				var schemaVersioning = new preside.system.api.presideObjects.sqlSchemaVersioning(
					  adapterFactory = adapterFactory
					, sqlRunner      = sqlRunner
					, dbInfoService  = dbInfoService
				);
				var schemaSync = new preside.system.api.presideObjects.sqlSchemaSynchronizer(
					  adapterFactory          = adapterFactory
					, sqlRunner               = sqlRunner
					, dbInfoService           = dbInfoService
					, schemaVersioningService = schemaVersioning
				);
				var relationshipGuidance = new preside.system.api.presideObjects.relationshipGuidance(
					  objectReader = objReader
				);
				var presideObjectDecorator = new preside.system.api.presideObjects.presideObjectDecorator();

				request._presideObjectService = new preside.system.api.presideObjects.PresideObjectService(
					  objectDirectories      = arguments.objectDirectories
					, objectReader           = objReader
					, sqlSchemaSynchronizer  = schemaSync
					, adapterFactory         = adapterFactory
					, sqlRunner              = sqlRunner
					, relationshipGuidance   = relationshipGuidance
					, presideObjectDecorator = presideObjectDecorator
					, objectCache            = cachebox.getCache( "SystemCache" )
					, defaultQueryCache      = cachebox.getCache( "defaultQueryCache" )
				);
			}

			return request._presideObjectService;
		</cfscript>
	</cffunction>

	<cffunction name="_insertData" access="private" returntype="any" output="false">
		<cfreturn _getPresideObjectService().insertData( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="_selectData" access="private" returntype="query" output="false">
		<cfreturn _getPresideObjectService().selectData( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="_deleteData" access="private" returntype="numeric" output="false">
		<cfreturn _getPresideObjectService().deleteData( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="_dbSync" access="private" returntype="void" output="false">
		<cfreturn _getPresideObjectService().dbSync( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="_bCryptPassword" access="private" returntype="string" output="false">
		<cfargument name="pw" type="string" required="true" />

		<cfreturn _getBCrypt().hashPw( arguments.pw ) />
	</cffunction>

	<cffunction name="_emptyDatabase" access="private" returntype="any" output="false">
		<cfset var tables = _getDbTables() />
		<cfset var table  = "" />
		<cfset var fks    = "" />
		<cfset var fk     = "" />

		<cfloop list="#tables#" index="table">
			<cfset fks = _getTableForeignKeys( table ) />
			<cfloop collection="#fks#" item="fk">
				<cfquery datasource="#application.dsn#">
					alter table #fks[fk].fk_table# drop foreign key #fk#
				</cfquery>
			</cfloop>
		</cfloop>
		<cfloop list="#tables#" index="table">
			<cfquery datasource="#application.dsn#">
				drop table #table#
			</cfquery>
		</cfloop>
	</cffunction>

	<cffunction name="_getDbTables" access="private" returntype="string" output="false">
		<cfset var tables = "" />
		<cfdbinfo type="tables" name="tables" datasource="#application.dsn#" />
		<cfreturn ValueList( tables.table_name ) />
	</cffunction>

	<cffunction name="_getTableForeignKeys" access="private" returntype="struct" output="false">
		<cfargument name="table" type="string" required="true" />

		<cfscript>
			var keys        = "";
			var key         = "";
			var constraints = {};
			var rules       = {};

			rules["0"] = "cascade";
			rules["2"] = "set null";

			dbinfo type="Foreignkeys" table=arguments.table datasource="#application.dsn#" name="keys";
			for( key in keys ){
				constraints[ key.fk_name ] = {
					  pk_table  = key.pktable_name
					, fk_table  = key.fktable_name
					, pk_column = key.pkcolumn_name
					, fk_column = key.fkcolumn_name
				}

				if ( StructKeyExists( rules, key.update_rule ) ) {
					constraints[ key.fk_name ].on_update = rules[ key.update_rule ];
				} else {
					constraints[ key.fk_name ].on_update = "error";
				}

				if ( StructKeyExists( rules, key.delete_rule ) ) {
					constraints[ key.fk_name ].on_delete = rules[ key.delete_rule ];
				} else {
					constraints[ key.fk_name ].on_delete = "error";
				}
			}

			return constraints;
		</cfscript>
	</cffunction>

	<cffunction name="_getTableIndexes" access="private" returntype="struct" output="false">
		<cfargument name="tableName" type="string" required="true" />

		<cfscript>
			var indexes = "";
			var index   = "";
			var ixs     = {};

			dbinfo type="index" table="#arguments.tableName#" name="indexes" datasource="#application.dsn#";

			for( index in indexes ){
				if ( index.index_name neq "PRIMARY" ) {
					if ( not StructKeyExists( ixs, index.index_name ) ){
						ixs[ index.index_name ] = {
							  unique = not index.non_unique
							, fields = ""
						}
					}

					ixs[ index.index_name ].fields = ListAppend( ixs[ index.index_name ].fields, index.column_name );
				}
			}

			return ixs;
		</cfscript>
	</cffunction>

	<cffunction name="_getTableColumns" access="private" returntype="query" output="false">
		<cfargument name="tableName" type="string" required="true" />

		<cfscript>
			var columns = "";

			dbinfo type="columns" name="columns" table=arguments.tableName datasource=application.dsn;

			return columns;
		</cfscript>
	</cffunction>

</cfcomponent>