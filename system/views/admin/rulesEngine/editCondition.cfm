<cfoutput>
	#renderView( view="/admin/datamanager/_editRecordForm", args={
		  object           = "rules_engine_condition"
		, id               = rc.id      ?: ""
		, record           = prc.record ?: {}
		, editRecordAction = event.buildAdminLink( linkTo='rulesEngine.editConditionAction' )
		, cancelAction     = event.buildAdminLink( linkTo='rulesEngine' )
	} )#
</cfoutput>