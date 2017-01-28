<cfparam name="args.id"   type="string" />
<cfparam name="args.name" type="string" />

<cfoutput>
	<div class="action-buttons">
		<a class="blue" href="#event.buildAdminLink( linkTo="sites.editSite", queryString="id=#args.id#&action=manage")#" data-context-key="e">
			<i class="fa fa-pencil bigger-130"></i>
		</a>

		<a class="red" data-context-key="p" href="#event.buildAdminLink( linkTo="sites.editPermissions", queryString="id=#args.id#" )#">
			<i class="fa fa-lock bigger-130"></i>
		</a>
	</div>
</cfoutput>