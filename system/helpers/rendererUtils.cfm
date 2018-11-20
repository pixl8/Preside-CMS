<cffunction name="renderEmailTrackingLink" access="public" returntype="string" output="false">
	<cfargument name="link"       type="string" required="true" />
	<cfargument name="link_title" type="string" required="true" />
	<cfargument name="link_body"  type="string" required="true" />

	<cfscript>
		var linkTitle = Len( Trim( arguments.link_title ) ) ? "#arguments.link_title# (#arguments.link#)" : "";
		var linkBody  = Len( Trim( arguments.link_body ) ) ? arguments.link_body : ( Len( Trim( arguments.link_title ) ) ? arguments.link_title : arguments.link );

		return '<a href="#arguments.link#" title="#linkTitle#">#Abbreviate( linkBody, 70 )#</a>';
	</cfscript>
</cffunction>