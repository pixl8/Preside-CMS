<cfoutput>
	#renderView( view="/admin/datamanager/_addRecordForm", args={
		  objectName            = "url_redirect_rule"
		, addRecordAction       = event.buildAdminLink( linkTo='urlRedirects.addRuleAction' )
		, allowAddAnotherSwitch = true
		, cancelAction          = event.buildAdminLink( linkTo='urlRedirects' )
	} )#
</cfoutput>