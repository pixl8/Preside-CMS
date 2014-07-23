<cfoutput>
	#renderView( view="/admin/datamanager/_addRecordForm", args={
		  objectName            = "site"
		, addRecordAction       = event.buildAdminLink( linkTo='sites.addSiteAction' )
		, cancelAction          = event.buildAdminLink( linkTo='sites.manage' )
		, allowAddAnotherSwitch = false
	} )#
</cfoutput>