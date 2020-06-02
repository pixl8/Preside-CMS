<cfoutput>
	#renderView( view="/admin/datamanager/_addRecordForm", args={
		  objectName            = "email_blueprint"
		, addRecordAction       = event.buildAdminLink( linkTo='emailCenter.Blueprints.addAction' )
		, cancelAction          = event.buildAdminLink( linkTo='emailCenter.Blueprints' )
		, draftsEnabled         = false
		, allowAddAnotherSwitch = false
	} )#
</cfoutput>