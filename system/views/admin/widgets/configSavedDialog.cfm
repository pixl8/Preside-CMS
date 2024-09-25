<!---@feature admin--->
<cfscript>
	prc.pageTitle    = translateResource( "cms:widget.saved" );
	prc.pageSubTitle = translateResource( "cms:widget.saved.subtitle" );
</cfscript>

<cfoutput>
	#outputView( view="/admin/widgets/_dialogLayout", args={ body=translateResource( "cms:widget.saved.message" ) } )#
</cfoutput>