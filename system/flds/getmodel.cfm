<cffunction name="getmodel" access="public" returntype="any" output="false">
	<cfreturn application.cbbootstrap.getController().getWirebox().getInstance( argumentCollection=arguments ) />
</cffunction>