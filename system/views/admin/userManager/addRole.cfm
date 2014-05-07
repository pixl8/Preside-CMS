<cfscript>
	prc.pageIcon  = "group";
	prc.pageTitle = translateResource( "cms:usermanager.addRole.page.title" );
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_addRecordForm", args={
		  objectName            = "security_role"
		, addRecordAction       = event.buildAdminLink( linkTo='usermanager.addRoleAction' )
		, allowAddAnotherSwitch = true
		, cancelAction          = event.buildAdminLink( linkTo='usermanager.roles' )
	} )#
</cfoutput>