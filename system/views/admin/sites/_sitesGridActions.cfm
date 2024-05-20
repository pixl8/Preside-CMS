<!---@feature admin and sites--->
<cfparam name="args.id"   type="string" />
<cfparam name="args.name" type="string" />

<cfoutput>
	<div class="action-buttons">
		<a class="blue" href="#event.buildAdminLink( linkTo="sites.editSite", queryString="id=#args.id#&action=manage")#" data-context-key="e">
			<i class="fa fa-pencil bigger-130"></i>
		</a>

		<a class="green" href="#event.buildAdminLink( linkTo="sites.cloneSite", queryString="id=#args.id#")#" data-context-key="c">
			<i class="fa fa-clone bigger-130"></i>
		</a>

		<a class="grey" data-context-key="p" href="#event.buildAdminLink( linkTo="sites.editPermissions", queryString="id=#args.id#" )#">
			<i class="fa fa-lock bigger-130"></i>
		</a>

		<cfif event.getSiteId() == args.id>
			<a class="light-grey">
				<i class="fa fa-trash bigger-130"></i>
			</a>
		<cfelse>
			<a class="red" data-context-key="d" href="#event.buildAdminLink( linkTo="sites.deleteSite", queryString="id=#args.id#" )#">
				<i class="fa fa-trash bigger-130"></i>
			</a>
		</cfif>
	</div>
</cfoutput>