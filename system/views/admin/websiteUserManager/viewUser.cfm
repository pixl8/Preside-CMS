<cfscript>
	userId     = rc.id ?: "";
	userRecord = prc.record ?: {};

	prc.pageIcon  = "user";
	prc.pageTitle = translateResource( uri="cms:websiteUserManager.viewUser.page.title", data=[ prc.record.display_name ?: "" ] );

	canEdit        = hasCmsPermission( "websiteUserManager.edit" );
	canDelete      = hasCmsPermission( "websiteUserManager.delete" );
	canImpersonate = hasCmsPermission( "websiteUserManager.impersonate" );

	if ( canEdit ) {
		editRecordLink  = event.buildAdminLink( linkTo="websiteUserManager.editUser", queryString="id=#userId#")
		editRecordTitle = translateResource( "cms:websiteUserManager.editUser.btn" );

		changePasswordLink  = event.buildAdminLink( linkTo="websiteUserManager.changeUserPassword", queryString="id=#userId#" );
		changePasswordTitle = translateResource( "cms:websiteUserManager.changePassword.btn" );
	}

	if ( canDelete ) {
		deleteRecordLink   = event.buildAdminLink( linkTo="websiteUserManager.deleteUserAction", queryString="id=#userId#" )
		deleteRecordPrompt = translateResource( uri='cms:websiteUserManager.deleteUser.prompt', data=[ userRecord.display_name ] )
		deleteRecordTitle  = translateResource( "cms:websiteUserManager.deleteUser.btn" );
	}

	if ( canImpersonate ) {
		impersonateLink  = event.buildAdminLink( linkTo="websiteUserManager.impersonateUserAction", queryString="id=#userId#" )
		impersonateTitle = translateResource( "cms:websiteUserManager.impersonateUser.btn" );
	}
</cfscript>


<cfoutput>
	<div class="top-right-button-group">
		<cfif canDelete>
			<a class="pull-right inline confirmation-prompt" href="#deleteRecordLink#" title="#HtmlEditFormat( deleteRecordPrompt )#">
				<button class="btn btn-danger btn-sm">
					<i class="fa fa-trash-o"></i>
					#deleteRecordTitle#
				</button>
			</a>
		</cfif>
		<cfif canImpersonate>
			<a class="pull-right inline" data-global-key="i" href="#impersonateLink#">
				<button class="btn btn-default btn-sm">
					<i class="fa fa-user-md"></i>
					#impersonateTitle#
				</button>
			</a>
		</cfif>
		<cfif canEdit>
			<a class="pull-right inline" data-global-key="i" href="#changePasswordLink#">
				<button class="btn btn-warning btn-sm">
					<i class="fa fa-key"></i>
					#changePasswordTitle#
				</button>
			</a>
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
		, args  = { objectName="website_user", recordId=rc.id }
	)#
</cfoutput>