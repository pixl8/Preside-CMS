<cfparam name="args.id" type="string" />

<cfoutput>
	<div class="action-buttons btn-group">
		<a href="#event.buildAdminLink( linkTo='sitetree.editPage', queryString='id=#args.id#&version=#args._version_number#' )#" data-context-key="e" title="#HtmlEditFormat( translateResource( uri="cms:datatable.contextmenu.edit" ) )#">
			<i class="fa fa-pencil"></i>
		</a>
	</div>
</cfoutput>