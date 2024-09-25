<!---@feature admin and websiteUsers--->
<cfscript>
	prc.pageIcon  = "user";
	prc.pageTitle = translateResource( "cms:websiteusermanager.addUser.page.title" );
</cfscript>

<cfoutput>
	#outputView( view="/admin/datamanager/_addRecordForm", args={
		  objectName            = "website_user"
		, addRecordAction       = event.buildAdminLink( linkTo='websiteusermanager.addUserAction' )
		, allowAddAnotherSwitch = true
		, cancelAction          = event.buildAdminLink( linkTo='websiteusermanager' )
	} )#
</cfoutput>