<cfscript>
	template = rc.template ?: "";

	canPublish = hasCmsPermission( "emailcenter.systemtemplates.publish" );

	if ( canPublish ) {
		resetLink   = event.buildAdminLink( linkTo="emailcenter.systemTemplates.resetAction", queryString="template=#template#" );
		resetButton = translateResource( uri="cms:emailcenter.systemTemplates.reset.btn" );
		resetPrompt = translateResource( uri="cms:emailcenter.systemTemplates.reset.btn.prompt", data=[ prc.template.name ?: "" ] );
	}
</cfscript>

<cfoutput>
	<div class="top-right-button-group">
		<cfif canPublish>
			<a class="pull-right btn btn-warning btn-sm inline confirmation-prompt" href="#resetLink#" title="#resetPrompt#">
				<i class="fa fa-fw fa-refresh"></i> #resetButton#
			</a>
		</cfif>
	</div>
</cfoutput>