<cfscript>
	templateId = rc.id ?: "";
	showClicks = IsTrue( prc.showClicks ?: "" );
</cfscript>
<cfoutput>
	<cfsavecontent variable="body">
		#renderViewlet(
			  event = "admin.emailcenter.templateStatsSummary"
			, args  = { templateId=templateId }
		)#
	</cfsavecontent>

	#renderViewlet( event="admin.emailcenter.customtemplates._customTemplateTabs", args={ body=body, tab="stats" } )#
</cfoutput>