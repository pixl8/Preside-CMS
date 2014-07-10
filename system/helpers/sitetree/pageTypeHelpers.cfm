<cffunction name="getAllowableChildPageTypes" access="public" returntype="any" output="false">
	<cfreturn getController().getWireBox().getInstance( "pageTypesService" ).getPageType( argumentCollection = arguments ).getAllowedChildTypes() />
</cffunction>