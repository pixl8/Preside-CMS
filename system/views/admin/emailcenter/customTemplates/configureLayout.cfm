<cfscript>
	configForm = prc.configForm ?: "";
</cfscript>
<cfoutput>
	<cfsavecontent variable="body">
		<p class="alert alert-info">
			<i class="fa fa-fw fa-info-circle"></i>
			#translateResource( "cms:emailcenter.customTemplates.configureLayout.override.explanation" )#
		</p>

		#configForm#
	</cfsavecontent>

	#renderViewlet( event="admin.emailcenter.customtemplates._customTemplateTabs", args={ body=body, tab="layout" } )#
</cfoutput>