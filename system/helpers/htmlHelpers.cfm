<cffunction name="getNextTabIndex" access="public" returntype="numeric" output="false"><cfsilent>
	<cfscript>
		var ev              = event ?: getRequestContext();
		var currentTabIndex = Val( ev.getValue( name="_currentTabIndex", defaultValue=0, private=true ) );

		ev.setValue( name="_currentTabIndex", value=++currentTabIndex, private=true );

		return currentTabIndex;
	</cfscript>
</cfsilent></cffunction>

<cffunction name="stripTags" access="public" returntype="string" output="false">
	<cfargument name="stringValue" type="string" required="true" /><cfsilent>
	<cfreturn ReReplaceNoCase( stringValue , "<[^>]*>","", "all" ) />
</cfsilent></cffunction>

<cffunction name="hasTags" access="public" returntype="boolean" output="false">
	<cfargument name="stringValue" type="string" required="true" /><cfsilent>
	<cfreturn IsTrue( ReFind(  "<[^>]*>",stringValue ) ) />
</cfsilent></cffunction>
