<cfcomponent output="false" extends="testbox.system.BaseSpec" hint="An utility base class for our test cases">

<!--- private --->
	<cffunction name="_getCachebox" access="private" returntype="any" output="false">
		<cfargument name="forceNewInstance" type="boolean" required="false" default="false" />
		<cfargument name="cacheKey" type="string" required="false" default="_cachebox" />
		<cfscript>
			if ( arguments.forceNewInstance ) {
				return new coldbox.system.cache.CacheFactory( config="preside.system.config.Cachebox" );
			}

			if ( !request.keyExists( arguments.cacheKey ) ) {
				request[ arguments.cacheKey ] = new coldbox.system.cache.CacheFactory( config="preside.system.config.Cachebox" );
			}

			return request[ arguments.cacheKey ];
		</cfscript>
	</cffunction>

	<cffunction name="_getMockInterceptorService" access="public" returntype="any" output="false">
		<cfscript>
			var interceptor = getMockBox().createEmptyMock( "coldbox.system.web.services.InterceptorService" );

			interceptor.$( "registerInterceptors", interceptor );
			interceptor.$( "processState" );
			interceptor.$( "registerInterceptor", interceptor );
			interceptor.$( "appendInterceptionPoints", [] );
			interceptor.$( "registerInterceptionPoint", interceptor );

			return interceptor;
		</cfscript>
	</cffunction>

	<cffunction name="_getTestLogger" access="private" returntype="any" output="false">
		<cfargument name="logLevel" type="string" required="false" default="ERROR" />

		<cfreturn new tests.resources.HelperObjects.TestLogger( logLevel = arguments.logLevel ) />
	</cffunction>

	<cffunction name="_getBCrypt" access="private" returntype="any" output="false">
		<cfreturn new preside.system.services.encryption.bcrypt.BCryptService() />
	</cffunction>

	<cffunction name="_getPresideObjectService" access="private" returntype="any" output="false">
		<cfargument name="objectDirectories"         type="array"   required="false" default="#ListToArray( '/preside/system/preside-objects' )#" />
		<cfargument name="defaultPrefix"             type="string"  required="false" default="pobj_" />
		<cfargument name="forceNewInstance"          type="boolean" required="false" default="false" />
		<cfargument name="interceptorService"        type="any"     required="false" default="#_getMockInterceptorService()#" />
		<cfargument name="cachebox"                  type="any"     required="false" />
		<cfargument name="coldbox"                   type="any"     required="false" />
		<cfargument name="selectDataViewService"     type="any"     required="false" default="#createStub()#" />
		<cfargument name="msSqlUseVarcharMaxForText" type="boolean" required="false" default="false" />

		<cfscript>
			var key = "_presideObjectService" & Hash( SerializeJson( arguments ) );

			if ( arguments.forceNewInstance || !request.keyExists( key ) ) {
				var logger = _getTestLogger();
				var mockFeatureService = getMockBox().createEmptyMock( "preside.system.services.features.FeatureService" );
				var mockRequestContext = getMockBox().createStub();
				var cachebox       = arguments.cachebox ?: _getCachebox( cacheKey="_cacheBox" & key, forceNewInstance=arguments.forceNewInstance );
				var dbInfoService  = new preside.system.services.database.DbInfoService();
				var sqlRunner      = new preside.system.services.database.sqlRunner( logger = logger );

				var adapterFactory = new preside.system.services.database.adapters.AdapterFactory( dbInfoService=dbInfoService, msSqlUseVarcharMaxForText=arguments.msSqlUseVarcharMaxForText );
				var objReader = new preside.system.services.presideObjects.PresideObjectReader(
					  dsn = application.dsn
					, tablePrefix = arguments.defaultPrefix
					, interceptorService = arguments.interceptorService
					, featureService = mockFeatureService
					, adapterFactory = adapterFactory
				);
				var schemaVersioning = new preside.system.services.presideObjects.sqlSchemaVersioning(
					  adapterFactory = adapterFactory
					, sqlRunner      = sqlRunner
					, dbInfoService  = dbInfoService
				);
				var schemaSync = new preside.system.services.presideObjects.sqlSchemaSynchronizer(
					  adapterFactory              = adapterFactory
					, sqlRunner                   = sqlRunner
					, dbInfoService               = dbInfoService
					, schemaVersioningService     = schemaVersioning
					, autoRunScripts              = true
					, autoRestoreDeprecatedFields = true
				);
				var relationshipGuidance = new preside.system.services.presideObjects.relationshipGuidance(
					  objectReader          = objReader
					, selectDataViewService = createStub()
				);
				var presideObjectDecorator = new preside.system.services.presideObjects.presideObjectDecorator();

				var coldbox = arguments.coldbox ?: getMockbox().createEmptyMock( "preside.system.coldboxModifications.Controller" );
				var versioningService = getMockBox().createMock( object=new preside.system.services.presideObjects.VersioningService() );

				var mockLabelRendererCache = getMockBox().createStub();
				var labelRendererService = getMockBox().createMock( object= new preside.system.services.rendering.LabelRendererService(
					labelRendererCache = mockLabelRendererCache
				) );

				mockFilterService = getMockBox().createStub();
				mockFilterService.$( "getFilter", {} );
				mockFeatureService.$( "isFeatureEnabled", true );

				mockRequestContext.$( "isAdminUser", true );
				mockRequestContext.$( "getAdminUserId", "" );
				mockRequestContext.$( "getUseQueryCache", true );
				if ( !StructKeyExists( arguments, "coldbox" ) ) {
					coldbox.$( "getRequestContext", mockRequestContext );
				}

				request[ key ] = new preside.system.services.presideObjects.PresideObjectService(
					  objectDirectories      = arguments.objectDirectories
					, objectReader           = objReader
					, sqlSchemaSynchronizer  = schemaSync
					, adapterFactory         = adapterFactory
					, sqlRunner              = sqlRunner
					, relationshipGuidance   = relationshipGuidance
					, presideObjectDecorator = presideObjectDecorator
					, filterService          = mockFilterService
					, versioningService      = versioningService
					, labelRendererService   = labelRendererService
					, defaultQueryCache      = cachebox.getCache( "defaultQueryCache" )
					, coldboxController      = coldbox
					, interceptorService     = arguments.interceptorService
					, selectDataViewService  = arguments.selectDataViewService
					, reloadDb               = false
				);
				request[ key ] = getMockbox().createMock( object=request[ key ] );

				versioningService.$( "$getPresideObjectService", request[ key ] );
				versioningService.$( "$getAdminLoggedInUserId", "" );
				request[ key ].$( "$isAdminUserLoggedIn", false );
				request[ key ].$( "$getRequestContext", mockRequestContext );
				request[ key ].$( "$isFeatureEnabled" ).$args( "queryCachePerObject" ).$results( false );
				mockRequestContext.$( "showNonLiveContent", false );
			}

			request[ '_mostRecentPresideObjectFetch' ] = request[ key ];

			return request[ key ];
		</cfscript>
	</cffunction>

	<cffunction name="_insertData" access="private" returntype="any" output="false">
		<cfreturn ( request[ '_mostRecentPresideObjectFetch' ] ?: _getPresideObjectService() ).insertData( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="_selectData" access="private" returntype="query" output="false">
		<cfreturn ( request[ '_mostRecentPresideObjectFetch' ] ?: _getPresideObjectService() ).selectData( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="_deleteData" access="private" returntype="numeric" output="false">
		<cfreturn ( request[ '_mostRecentPresideObjectFetch' ] ?: _getPresideObjectService() ).deleteData( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="_dbSync" access="private" returntype="void" output="false">
		<cfreturn ( request[ '_mostRecentPresideObjectFetch' ] ?: _getPresideObjectService() ).dbSync( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="_clearRecentPresideServiceFetch" access="private" returntype="void" output="false">
		<cfset StructDelete( request, "_mostRecentPresideObjectFetch" ) />
	</cffunction>

	<cffunction name="_bCryptPassword" access="private" returntype="string" output="false">
		<cfargument name="pw" type="string" required="true" />

		<cfreturn _getBCrypt().hashPw( arguments.pw ) />
	</cffunction>

	<cffunction name="_emptyDatabase" access="private" returntype="any" output="false">
		<cfset var dbAdapter = _getDbAdapter() />
		<cfset var tables    = _getDbTables() />
		<cfset var table     = "" />
		<cfset var fks       = "" />
		<cfset var fk        = "" />

		<cfloop list="#tables#" index="table">
			<cfset fks = _getTableForeignKeys( table ) />
			<cfloop collection="#fks#" item="fk">
				<cfquery datasource="#application.dsn#">
					#dbAdapter.getDropForeignKeySql( foreignKeyName=fk, tableName=fks[fk].fk_table )#
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
		<cfscript>
			var tableInfo       = "";
			var tables          = [];
			var reservedSchemas = [ "sys", "information_schema" ]

			dbinfo type="tables" name="tableInfo" datasource=application.dsn;

			for( var table in tableInfo ){
				var isInReservedSchema = reservedSchemas.find( table.table_schem ?: "" );
				var isPhysicalTable    = ( table.table_type ?: "table" ) == "table";
				if ( !isInReservedSchema && isPhysicalTable ) {
					tables.append( table.table_name );
				}
			}

			return tables.toList();
		</cfscript>
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

	<cffunction name="_getDbAdapter" access="private" returntype="any" output="false">
		<cfreturn new preside.system.services.database.adapters.AdapterFactory(
			  dbInfoService             = new preside.system.services.database.DbInfoService()
			, msSqlUseVarcharMaxForText = false
		).getAdapter( application.dsn ) />
	</cffunction>

</cfcomponent>