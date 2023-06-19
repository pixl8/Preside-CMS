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

<cffunction name="renderForHTMLAttributes" access="public" returntype="string" output="false">
	<cfargument name="htmlAttributeNames"  type="string" default="" />
	<cfargument name="htmlAttributeValues" type="string" default="" />
	<cfargument name="htmlAttributes"      type="struct" default="#StructNew()#" />
	<cfargument name="htmlAttributePrefix" type="string" default="data-" /><cfsilent>
	<cfscript>
		var rendered = [];

		var names = ListToArray( arguments.htmlAttributeNames, "," );
	 	for ( var i=1; i<=ArrayLen( names ); i++ ) {
	 		ArrayAppend( rendered, '#htmlAttributePrefix##names[ i ]#="#( ListGetAt( arguments.htmlAttributeValues, i, ",", true ) )#"' );
		}

		for ( var name in arguments.htmlAttributes ) {
			ArrayAppend( rendered, '#htmlAttributePrefix##name#="#arguments.htmlAttributes[ name ]#"' );
		}

		return ArrayToList( rendered, " " );
	</cfscript>
</cfsilent></cffunction>
