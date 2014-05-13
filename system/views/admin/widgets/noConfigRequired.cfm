<cfscript>
	widget      = args.widget ?: {};
	widgetTitle = translateResource( widget.title ?: "", widget.title ?: "" );
</cfscript>

<cfoutput>
	<p>#translateResource( uri="cms:widget.dialog.noConfigRequired", data=[ "<strong>#widgetTitle#</strong>"] )#</p>
</cfoutput>