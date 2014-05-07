<cfscript>
	prc.pageIcon  = "user";
	prc.pageTitle = translateResource( "cms:usermanager.addUser.page.title" );
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_addRecordForm", args={
		  objectName            = "security_user"
		, addRecordAction       = event.buildAdminLink( linkTo='usermanager.addUserAction' )
		, allowAddAnotherSwitch = true
		, cancelAction          = event.buildAdminLink( linkTo='usermanager.users' )
	} )#
</cfoutput>