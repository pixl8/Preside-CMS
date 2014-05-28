<cfparam name="args.id"    type="string" />
<cfparam name="args.label" type="string" />

<cfoutput>
	<div class="action-buttons">
		<cfif hasPermission( "usermanager.edit" )>
			<a class="blue" href="#event.buildAdminLink( linkTo="usermanager.editUser", queryString="id=#args.id#")#" data-context-key="e">
				<i class="fa fa-pencil bigger-130"></i>
			</a>
		</cfif>

		<cfif hasPermission( "usermanager.delete" )>
			<cfif args.id != event.getAdminUserId()>
				<a class="red confirmation-prompt" data-context-key="d" href="#event.buildAdminLink( linkTo="userManager.deleteUserAction", queryString="id=#args.id#" )#" title="#translateResource( uri='cms:usermanager.deleteUser.prompt', data=[args.label] )#">
					<i class="fa fa-trash-o bigger-130"></i>
				</a>
			<cfelse>
				<i class="grey fa fa-trash-o bigger-130"></i>
			</cfif>
		</cfif>
	</div>
</cfoutput>