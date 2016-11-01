<cfscript>
	param name="prc.record"       type="struct";
	param name="prc.cancelAction" type="string";
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_editRecordForm", args={
		  object           = "site"
		, id               = rc.id      ?: ""
		, record           = prc.record ?: {}
		, editRecordAction = event.buildAdminLink( linkTo='sites.editSiteAction' )
		, cancelAction     = prc.cancelAction
	} )#
</cfoutput>