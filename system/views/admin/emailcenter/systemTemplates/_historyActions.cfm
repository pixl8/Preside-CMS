<cfparam name="args.id"              />
<cfparam name="args._version_number" />

<cfscript>
	editLink  = event.buildAdminLink( linkTo="emailCenter.systemTemplates.edit", queryString="template=#args.id#&version=#args._version_number#" );
	editTitle = HtmlEditFormat( translateResource( uri="cms:emailcenter.systemTemplates.versionHistory.editLink.title" ) );

	previewLink  = event.buildAdminLink( linkTo="emailCenter.systemTemplates.template", queryString="template=#args.id#&version=#args._version_number#" );
	previewTitle = HtmlEditFormat( translateResource( uri="cms:emailcenter.systemTemplates.versionHistory.previewLink.title" ) );
</cfscript>

<cfoutput>
	<div class="action-buttons btn-group">
		<a href="#previewLink#" data-context-key="p" title="#previewTitle#">
			<i class="fa fa-eye blue"></i>
		</a>
		<a href="#editLink#" data-context-key="e" title="#editTitle#">
			<i class="fa fa-pencil green"></i>
		</a>
	</div>
</cfoutput>