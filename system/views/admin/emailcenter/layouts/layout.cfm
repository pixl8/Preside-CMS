<cfoutput>
	<cfsavecontent variable="body">
	</cfsavecontent>

	#renderView( view="/admin/emailcenter/layouts/_layoutTabs", args={ body=body, tab="preview" } )#
</cfoutput>