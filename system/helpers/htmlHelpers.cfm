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

<cffunction name="renderHtmlAttributes" access="public" returntype="string" output="false">
	<cfargument name="attribs"      type="struct" default="#StructNew()#" />
	<cfargument name="attribNames"  type="string" default="" />
	<cfargument name="attribValues" type="string" default="" />
	<cfargument name="attribPrefix" type="string" default="" /><cfsilent>
	<cfscript>
		var rendered = [];

		var names  = ListToArray( arguments.attribNames );
		var values = ListToArray( arguments.attribValues );

		for ( var i=1; i<=ArrayLen( names ); i++ ) {
			arguments.attribs[ names[ i ] ] = values[ i ] ?: "";
		}

		for ( var key in arguments.attribs ) {
			var encodedName  = EncodeForHTMLAttribute( arguments.attribPrefix & key );
			var encodedValue = EncodeForHTMLAttribute( arguments.attribs[ key ] );

			ArrayAppend( rendered, '#encodedName#="#encodedValue#"' );
		}

		return ArrayToList( rendered, " " );
	</cfscript>
</cfsilent></cffunction>
