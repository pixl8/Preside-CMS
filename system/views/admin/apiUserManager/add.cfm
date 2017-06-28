<cfoutput>
	#renderView( view="/admin/datamanager/_addRecordForm", args={
		  objectName            = "rest_user"
		, addRecordAction       = event.buildAdminLink( linkTo='apiUserManager.addAction' )
		, cancelAction          = event.buildAdminLink( linkTo='apiUserManager' )

		, allowAddAnotherSwitch = true
	} )#
</cfoutput>