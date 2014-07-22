<cfscript>
	param name="prc.record" type="struct";
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_editRecordForm", args={
		  object           = "site"
		, id               = rc.id      ?: ""
		, record           = prc.record ?: {}
		, editRecordAction = event.buildAdminLink( linkTo='sites.editSiteAction' )
		, cancelAction     = event.buildAdminLink( linkTo='sites.manage' )
	} )#
</cfoutput>