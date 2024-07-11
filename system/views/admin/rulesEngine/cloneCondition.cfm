<!---@feature admin and rulesEngine--->
<cfoutput>
	#renderView( view="/admin/datamanager/_cloneRecordForm", args={
		  object            = "rules_engine_condition"
		, id                = rc.id      ?: ""
		, cloneableData     = prc.record ?: {}
		, cloneRecordAction = event.buildAdminLink( linkTo='rulesEngine.cloneConditionAction' )
		, cancelAction      = event.buildAdminLink( objectName='rules_engine_condition' )
		, formName          = prc.formName ?: ""
		, additionalArgs    = prc.additionalArgs ?: {}
	} )#
</cfoutput>