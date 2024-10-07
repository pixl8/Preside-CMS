<!---@feature admin--->
<cfscript>
	prc.pageIcon  = "group";
	prc.pageTitle = translateResource( uri="cms:usermanager.viewUser.page.title", data=[ prc.record.known_as ?: "" ] );

	userId     = rc.id ?: "";
	userRecord = prc.record ?: QueryNew('');

	canEdit     = hasCmsPermission( "usermanager.edit" );
	canDelete   = hasCmsPermission( "usermanager.delete" ) && userId != event.getAdminUserId();
	canReset2fa = hasCmsPermission( "usermanager.edit" ) && isTrue( userRecord.two_step_auth_key_in_use ?: "" );

	deletionConfirmationMatch = prc.deletionConfirmationMatch ?: "";

	if ( canEdit ) {
		editRecordLink  = event.buildAdminLink( linkTo="usermanager.editUser", queryString="id=#userId#" );
		editRecordTitle = translateResource( "cms:usermanager.editUser.btn" );
	}

	if ( canDelete ) {
		deleteRecordLink   = event.buildAdminLink( linkTo="userManager.deleteUserAction", queryString="id=#userId#" );
		deleteRecordPrompt = translateResource( uri='cms:usermanager.deleteUser.prompt', data=[ userRecord.known_as ?: "" ] );
		deleteRecordTitle  = translateResource( "cms:usermanager.deleteUser.btn" );
	}

	if ( canReset2fa ) {
		reset2faLink   = event.buildAdminLink( linkTo="userManager.resetTwoFactorAuthenticationAction", queryString="id=#userId#" );
		reset2faPrompt = translateResource( uri="cms:usermanager.reset2fa.prompt", data=[ userRecord.known_as ?: "" ] );
		reset2faTitle  = translateResource( "cms:usermanager.reset2fa.btn" );
		reset2faMatch  = translateResource( "cms:usermanager.reset2fa.match" );
	}
</cfscript>

<cfoutput>
	<div class="top-right-button-group">
		<cfif canReset2fa>
			<a class="pull-left inline confirmation-prompt" href="#reset2faLink#" title="#HtmlEditFormat( reset2faPrompt )#" data-confirmation-match="#reset2faMatch#">
				<button class="btn btn-sm">
					<i class="fa fa-user-secret"></i>
					#reset2faTitle#
				</button>
			</a>
		</cfif>
		<cfif canDelete>
			<a class="pull-right inline confirmation-prompt" href="#deleteRecordLink#" title="#HtmlEditFormat( deleteRecordPrompt )#"<cfif not isEmptyString( deletionConfirmationMatch )> data-confirmation-match="#deletionConfirmationMatch#"</cfif>>
				<button class="btn btn-danger btn-sm">
					<i class="fa fa-trash-o"></i>
					#deleteRecordTitle#
				</button>
			</a>
		</cfif>
		<cfif canEdit>
			<a class="pull-right inline" data-global-key="e" href="#editRecordLink#">
				<button class="btn btn-success btn-sm">
					<i class="fa fa-pencil"></i>
					#editRecordTitle#
				</button>
			</a>
		</cfif>
	</div>

	#renderViewlet(
		  event = "admin.dataHelpers.viewRecord"
		, args  = { objectName="security_user", recordId=rc.id }
	)#
</cfoutput>