<cfoutput>
	#renderView( view="/admin/datamanager/_editRecordForm", args={
		  object           = "url_redirect_rule"
		, id               = rc.id      ?: ""
		, record           = prc.record ?: {}
		, editRecordAction = event.buildAdminLink( linkTo='urlRedirects.editRuleAction' )
		, cancelAction     = event.buildAdminLink( linkTo='urlRedirects' )
	} )#
</cfoutput>