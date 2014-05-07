<cfscript>
	prc.pageTitle    = translateResource( "cms:widget.saved" );
	prc.pageSubTitle = translateResource( "cms:widget.saved.subtitle" );
</cfscript>

<cfoutput>
	#renderView( view="/admin/widgets/_dialogLayout", args={ body=translateResource( "cms:widget.saved.message" ) } )#
</cfoutput>