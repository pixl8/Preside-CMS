<cfcomponent output="false" extends="tests.resources.HelperObjects.PresideTestCase">

	<cffunction name="test01_getAdapter_shouldReturnMySqlAdapter_whenDatasourceIsMySqlDb" returntype="void">
		<cfscript>
			var adapter = _getFactory().getAdapter( dsn = application.dsn );

			super.assertEquals( "preside.system.api.database.adapters.MySqlAdapter", GetMetaData( adapter ).name );
		</cfscript>
	</cffunction>

	<cffunction name="test02_getAdapter_shouldThrowError_whenDatasourceDoesNotExist" returntype="void">
		<cfscript>
			var errorThrown = false;

			try {
				_getFactory().getAdapter( dsn = "nonExistantDb" );

			} catch ( "PresideObjects.datasourceNotFound" e ) {
				super.assertEquals( "Datasource, [nonExistantDb], not found.", e.message );
				errorThrown = true;
			}

			super.assert( errorThrown, "No helpful error was thrown" );
		</cfscript>
	</cffunction>

<!--- private helpers --->
	<cffunction name="_getFactory" access="private" returntype="any" output="false">
		<cfscript>
			return new preside.system.api.database.adapters.AdapterFactory(
				  cache         = _getCachebox().getCache( "SystemCache" )
				, dbInfoService = new preside.system.api.database.Info()
			);
		</cfscript>
	</cffunction>

</cfcomponent>