<cfscript>
	prc.pageIcon  = "group";
	prc.pageTitle = translateResource( uri="cms:usermanager.editGroup.page.title", data=[ prc.record.label ?: "" ] );
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_editRecordForm", args={
		  object           = "security_group"
		, id               = rc.id      ?: ""
		, record           = prc.record ?: {}
		, editRecordAction = event.buildAdminLink( linkTo='userManager.editGroupAction' )
		, cancelAction     = event.buildAdminLink( linkTo='usermanager.groups' )
	} )#
</cfoutput>