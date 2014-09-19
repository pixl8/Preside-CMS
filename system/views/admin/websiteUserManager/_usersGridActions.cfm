<cfparam name="args.id"       type="string" />
<cfparam name="args.display_name" type="string" />

<cfoutput>
	<div class="action-buttons">
		<cfif hasCmsPermission( "websiteUserManager.edit" )>
			<a class="blue" href="#event.buildAdminLink( linkTo="websiteUserManager.editUser", queryString="id=#args.id#")#" data-context-key="e">
				<i class="fa fa-pencil bigger-130"></i>
			</a>
		</cfif>

		<cfif hasCmsPermission( "websiteUserManager.delete" )>
			<cfif args.id != event.getAdminUserId()>
				<a class="red confirmation-prompt" data-context-key="d" href="#event.buildAdminLink( linkTo="websiteUserManager.deleteUserAction", queryString="id=#args.id#" )#" title="#translateResource( uri='cms:websiteUserManager.deleteUser.prompt', data=[args.display_name] )#">
					<i class="fa fa-trash-o bigger-130"></i>
				</a>
			<cfelse>
				<i class="grey fa fa-trash-o bigger-130"></i>
			</cfif>
		</cfif>
	</div>
</cfoutput>