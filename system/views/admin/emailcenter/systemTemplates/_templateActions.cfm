<!---@feature admin and emailCenter--->
<cfscript>
	template = rc.template ?: "";

	canPublish     = hasCmsPermission( "emailcenter.systemtemplates.publish" );
	contentHasDiff = args.contentHasDiff ?: false;

	if ( canPublish && contentHasDiff ) {
		resetLink   = event.buildAdminLink( linkTo="emailcenter.systemTemplates.reset", queryString="template=#template#" );
		resetButton = translateResource( uri="cms:emailcenter.systemTemplates.reset.btn" );
	}
</cfscript>

<cfoutput>
	<div class="top-right-button-group">
		<cfif canPublish && contentHasDiff>
			<a class="pull-right btn btn-warning btn-sm inline" href="#resetLink#">
				<i class="fa fa-fw fa-refresh"></i> #resetButton#
			</a>
		</cfif>
	</div>
</cfoutput>