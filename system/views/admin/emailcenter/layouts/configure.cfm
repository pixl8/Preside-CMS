<!---@feature admin and emailCenter--->
<cfscript>
	configForm = prc.configForm ?: "";
</cfscript>
<cfoutput>
	#outputView( view="/admin/emailcenter/layouts/_layoutTabs", args={ body=configForm, tab="configure" } )#
</cfoutput>