<cfscript>
	prc.pageIcon  = "user";
	prc.pageTitle = translateResource( uri="cms:websiteUserManager.editUser.page.title", data=[ prc.record.display_name ?: "" ] );
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_editRecordForm", args={
		  object            = "website_user"
		, id                = rc.id      ?: ""
		, record            = prc.record ?: {}
		, editRecordAction  = event.buildAdminLink( linkTo='websiteUserManager.editUserAction' )
		, cancelAction      = event.buildAdminLink( linkTo='websiteUserManager' )
	} )#
</cfoutput>