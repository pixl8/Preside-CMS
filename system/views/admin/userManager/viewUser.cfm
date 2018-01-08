<cfscript>
	prc.pageIcon  = "group";
	prc.pageTitle = translateResource( uri="cms:usermanager.viewUser.page.title", data=[ prc.record.known_as ?: "" ] );

	userId = rc.id ?: "";
	userRecord = prc.record ?: QueryNew('');

	canEdit   = hasCmsPermission( "usermanager.edit" );
	canDelete = hasCmsPermission( "usermanager.delete" ) && userId != event.getAdminUserId();

	if ( canEdit ) {
		editRecordLink = event.buildAdminLink( linkTo="usermanager.editUser", queryString="id=#userId#" );
		editRecordTitle = translateResource( "cms:usermanager.editUser.btn" );
	}

	if ( canDelete ) {
		deleteRecordLink = event.buildAdminLink( linkTo="userManager.deleteUserAction", queryString="id=#userId#" );
		deleteRecordPrompt = translateResource( uri='cms:usermanager.deleteUser.prompt', data=[ userRecord.known_as ?: "" ] );
		deleteRecordTitle = translateResource( "cms:usermanager.deleteUser.btn" );
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