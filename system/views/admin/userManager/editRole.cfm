<cfscript>
	prc.pageIcon  = "group";
	prc.pageTitle = translateResource( uri="cms:usermanager.editRole.page.title", data=[ prc.record.label ?: "" ] );
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_editRecordForm", args={
		  object           = "security_role"
		, id               = rc.id      ?: ""
		, record           = prc.record ?: {}
		, editRecordAction = event.buildAdminLink( linkTo='userManager.editRoleAction' )
		, cancelAction     = event.buildAdminLink( linkTo='usermanager.roles' )
	} )#
</cfoutput>