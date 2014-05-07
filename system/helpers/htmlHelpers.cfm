<cffunction name="getNextTabIndex" access="public" returntype="numeric" output="false">
	<cfscript>
		var ev              = event ?: getRequestContext();
		var currentTabIndex = Val( ev.getValue( name="_currentTabIndex", defaultValue=0, private=true ) );

		ev.setValue( name="_currentTabIndex", value=++currentTabIndex, private=true );

		return currentTabIndex;
	</cfscript>
</cffunction>