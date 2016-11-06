<cfparam name="args.id"              />
<cfparam name="args._version_number" />

<cfscript>
	editLink  = event.buildAdminLink( linkTo="emailCenter.systemTemplates.edit", queryString="template=#args.id#&version=#args._version_number#" );
	editTitle = HtmlEditFormat( translateResource( uri="cms:emailcenter.systemTemplates.versionHistory.editLink.title" ) );
</cfscript>

<cfoutput>
	<div class="action-buttons btn-group">
		<a href="#editLink#" data-context-key="e" title="#editTitle#">
			<i class="fa fa-pencil"></i>
		</a>
	</div>
</cfoutput>