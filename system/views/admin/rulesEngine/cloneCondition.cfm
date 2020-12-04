<cfscript>
	isFilter = Len( Trim( prc.record.filter_object ?: "" ) );
	formName = "preside-objects.rules_engine_condition.admin.clone" & ( isFilter ? ".filter" : "" );
</cfscript>
<cfoutput>
	#renderView( view="/admin/datamanager/_cloneRecordForm", args={
		  object            = "rules_engine_condition"
		, id                = rc.id      ?: ""
		, cloneableData     = prc.record ?: {}
		, cloneRecordAction = event.buildAdminLink( linkTo='rulesEngine.cloneConditionAction' )
		, cancelAction      = event.buildAdminLink( linkTo='rulesEngine' )
		, formName          = formName
	} )#
</cfoutput>