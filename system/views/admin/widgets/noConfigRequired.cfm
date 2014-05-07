<cfscript>
	widget      = args.widget ?: {};
	widgetTitle = translateResource( widget.title ?: "", widget.title ?: "" );
</cfscript>

<cfoutput>
	<cfsavecontent variable="body">
		<p>#translateResource( uri="cms:widget.dialog.noConfigRequired", data=[ "<strong>#widgetTitle#</strong>"] )#</p>
	</cfsavecontent>

	#renderView( view="/admin/widgets/_dialogLayout", args={ body=body } )#
</cfoutput>