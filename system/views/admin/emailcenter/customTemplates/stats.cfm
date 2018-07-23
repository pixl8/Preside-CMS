<cfscript>
	templateId = rc.id ?: "";
	showClicks = IsTrue( prc.showClicks ?: "" );
</cfscript>
<cfoutput>
	#renderViewlet( event="admin.emailcenter.customtemplates._customTemplateTabs", args={ body="TODO", tab="stats" } )#
</cfoutput>