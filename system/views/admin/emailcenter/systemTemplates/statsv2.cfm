<!---@feature admin and emailCenter--->
<cfscript>
	templateId = rc.template ?: ( rc.id ?: "" );
	showClicks = IsTrue( prc.showClicks ?: "" );
</cfscript>
<cfoutput>
	<cfsavecontent variable="body">
		#renderViewlet(
			  event = "admin.emailcenter.statsv2"
			, args  = { templateId=templateId }
		)#
	</cfsavecontent>

	#renderViewlet( event="admin.emailcenter.systemtemplates._templateTabs", args={ body=body, tab="stats" } )#
</cfoutput>