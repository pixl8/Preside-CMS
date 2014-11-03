<cffunction name="getAllowableChildPageTypes" access="public" returntype="any" output="false">
	<cfscript>
		var pageTypesService = getController().getWireBox().getInstance( "pageTypesService" );

		if ( pageTypesService.pageTypeExists( argumentCollection=arguments ) ) {
			return pageTypesService.getPageType( argumentCollection = arguments ).getAllowedChildTypes();
		}

		return "";
	</cfscript>
</cffunction>