<cfscript>
	configForm = prc.configForm ?: "";
</cfscript>
<cfoutput>
	#renderView( view="/admin/emailcenter/layouts/_layoutTabs", args={ body=configForm, tab="configure" } )#
</cfoutput>