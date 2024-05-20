<!---@feature admin--->
<cfparam name="args.id"       type="string" />
<cfparam name="args.known_as" type="string" />

<cfscript>
	batchDeletionConfirmationMatch = prc.batchDeletionConfirmationMatch ?: "";
</cfscript>

<cfoutput>
	<div class="action-buttons">
		<cfif hasCmsPermission( "usermanager.read" )>
			<a class="green" href="#event.buildAdminLink( linkTo="usermanager.viewUser", queryString="id=#args.id#")#" data-context-key="v">
				<i class="fa fa-eye"></i>
			</a>
		</cfif>

		<cfif hasCmsPermission( "usermanager.edit" )>
			<a class="blue" href="#event.buildAdminLink( linkTo="usermanager.editUser", queryString="id=#args.id#")#" data-context-key="e">
				<i class="fa fa-pencil"></i>
			</a>
		</cfif>

		<cfif hasCmsPermission( "usermanager.delete" )>
			<cfif args.id != event.getAdminUserId()>
				<a class="red confirmation-prompt" data-context-key="d" href="#event.buildAdminLink( linkTo="userManager.deleteUserAction", queryString="id=#args.id#" )#" title="#translateResource( uri='cms:usermanager.deleteUser.prompt', data=[args.known_as] )#"<cfif not isEmptyString( batchDeletionConfirmationMatch )> data-confirmation-match="#batchDeletionConfirmationMatch#"</cfif>>
					<i class="fa fa-trash-o"></i>
				</a>
			<cfelse>
				<i class="grey fa fa-trash-o"></i>
			</cfif>
		</cfif>
	</div>
</cfoutput>