<cfparam name="args.id"       type="string" />
<cfparam name="args.display_name" type="string" />

<cfoutput>
	<div class="action-buttons">
		<cfif hasCmsPermission( "websiteUserManager.read" )>
			<a class="green" href="#event.buildAdminLink( linkTo="websiteUserManager.viewUser", queryString="id=#args.id#")#" data-context-key="v">
				<i class="fa fa-eye"></i>
			</a>
		</cfif>

		<cfif hasCmsPermission( "websiteUserManager.edit" )>
			<a class="blue" href="#event.buildAdminLink( linkTo="websiteUserManager.editUser", queryString="id=#args.id#")#" data-context-key="e">
				<i class="fa fa-pencil"></i>
			</a>
		</cfif>

		<cfif hasCmsPermission( "websiteUserManager.delete" )>
			<a class="red confirmation-prompt" data-context-key="d" href="#event.buildAdminLink( linkTo="websiteUserManager.deleteUserAction", queryString="id=#args.id#" )#" title="#translateResource( uri='cms:websiteUserManager.deleteUser.prompt', data=[args.display_name] )#">
				<i class="fa fa-trash-o"></i>
			</a>
		</cfif>

		<cfif hasCmsPermission( "websiteUserManager.edit" )>
			<a class="green" href="#event.buildAdminLink( linkTo="websiteUserManager.changeUserPassword", queryString="id=#args.id#")#" data-context-key="p">
				<i class="fa fa-key"></i>
			</a>
		</cfif>

		<cfif hasCmsPermission( "websiteUserManager.impersonate" )>
			<a class="grey confirmation-prompt" data-context-key="i" href="#event.buildAdminLink( linkTo="websiteUserManager.impersonateUserAction", queryString="id=#args.id#" )#" title="#translateResource( uri='cms:websiteUserManager.impersonateUser.prompt', data=[args.display_name] )#">
				<i class="fa fa-user-md"></i>
			</a>
		</cfif>
	</div>
</cfoutput>