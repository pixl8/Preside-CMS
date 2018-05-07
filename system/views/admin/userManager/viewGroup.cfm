<cfscript>
	prc.pageIcon  = "group";
	prc.pageTitle = translateResource( uri="cms:usermanager.viewGroup.page.title", data=[ prc.record.label ?: "" ] );

	groupId = rc.id ?: "";
	groupRecord = prc.record ?: QueryNew('');

	canEdit   = hasCmsPermission( "groupmanager.edit" );
	canDelete = hasCmsPermission( "groupmanager.delete" );

	if ( canEdit ) {
		editRecordLink = event.buildAdminLink( linkTo="usermanager.editGroup", queryString="id=#groupId#" );
		editRecordTitle = translateResource( "cms:usermanager.editGroup.btn" );
	}

	if ( canDelete ) {
		deleteRecordLink = event.buildAdminLink( linkTo="userManager.deleteGroupAction", queryString="id=#groupId#" );
		deleteRecordPrompt = translateResource( uri='cms:usermanager.deleteGroup.prompt', data=[ groupRecord.label ?: "" ] );
		deleteRecordTitle = translateResource( "cms:usermanager.deleteGroup.btn" );
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
		, args  = { objectName="security_group", recordId=rc.id }
	)#
</cfoutput>