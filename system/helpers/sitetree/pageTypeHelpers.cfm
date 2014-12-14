<cffunction name="getAllowableChildPageTypes" access="public" returntype="any" output="false">
	<cfscript>
		var pageTypesService = getController().getWireBox().getInstance( "pageTypesService" );

		if ( pageTypesService.pageTypeExists( argumentCollection=arguments ) ) {
			return pageTypesService.getPageType( argumentCollection = arguments ).getAllowedChildTypes();
		}

		return "";
	</cfscript>
</cffunction>

<cffunction name="getManagedChildPageTypes" access="public" returntype="any" output="false">
	<cfscript>
		var pageTypesService = getController().getWireBox().getInstance( "pageTypesService" );

		if ( pageTypesService.pageTypeExists( argumentCollection=arguments ) ) {
			return pageTypesService.getPageType( argumentCollection = arguments ).getManagedChildTypes();
		}

		return "";
	</cfscript>
</cffunction>

<cffunction name="isSystemPageType" access="public" returntype="any" output="false">
	<cfscript>
		var pageTypesService = getController().getWireBox().getInstance( "pageTypesService" );

		return pageTypesService.pageTypeExists( argumentCollection=arguments ) && pageTypesService.isSystemPageType( argumentCollection=arguments );
	</cfscript>
</cffunction>