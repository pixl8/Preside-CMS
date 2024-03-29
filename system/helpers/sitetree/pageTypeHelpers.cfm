<cffunction name="getAllowableChildPageTypes" access="public" returntype="any" output="false"><cfsilent>
	<cfscript>
		var args     = arguments;
		var cacheKey = "getAllowableChildPageTypes" & SerializeJson( args );

		return simpleRequestCache( cacheKey, function(){
			var pageTypesService = getSingleton( "pageTypesService" );

			if ( pageTypesService.pageTypeExists( argumentCollection=args ) ) {
				return pageTypesService.getPageType( argumentCollection=args ).getAllowedChildTypes();
			}

			return "";
		} );
	</cfscript>
</cfsilent></cffunction>

<cffunction name="getManagedChildPageTypes" access="public" returntype="any" output="false"><cfsilent>
	<cfscript>
		var args     = arguments;
		var cacheKey = "getManagedChildPageTypes" & SerializeJson( args );

		return simpleRequestCache( cacheKey, function(){
			var pageTypesService = getSingleton( "pageTypesService" );

			if ( pageTypesService.pageTypeExists( argumentCollection=args ) ) {
				return pageTypesService.getPageType( argumentCollection=args ).getManagedChildTypes();
			}

			return "";
		} );
	</cfscript>
</cfsilent></cffunction>

<cffunction name="isSystemPageType" access="public" returntype="any" output="false"><cfsilent>
	<cfscript>
		var args     = arguments;
		var cacheKey = "isSystemPageType" & SerializeJson( args );

		return simpleRequestCache( cacheKey, function(){
			var pageTypesService = getSingleton( "pageTypesService" );

			return pageTypesService.pageTypeExists( argumentCollection=args ) && pageTypesService.isSystemPageType( argumentCollection=args );
		} );
	</cfscript>
</cfsilent></cffunction>

<cffunction name="quickBuildLink" access="public" returntype="any" output="false">
	<cfargument name="link" type="string" required="true" />
	<cfargument name="args" type="struct" required="true" /><cfsilent>
	<cfscript>
		var built = Trim( link );
		for( var key in args ) {
			built = ReplaceNoCase( built, "{#key#}", args[key], "all" );
		}
		return built;
	</cfscript>
</cfsilent></cffunction>