<cffunction name="rssDateFormat" access="public" returntype="string" output="false">
	<cfargument name="date"     type="date"   required="true" />
	<cfargument name="timezone" type="string" required="false" default="GMT" />

	<cfreturn DateFormat( arguments.date, "ddd, dd MMM YYYY " ) & TimeFormat( arguments.date, "HH:mm:ss " ) & arguments.timezone />
</cffunction>