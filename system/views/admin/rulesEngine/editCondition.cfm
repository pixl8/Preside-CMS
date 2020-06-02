<cfscript>
	isFilter = Len( Trim( prc.record.filter_object ?: "" ) );
	formName = "preside-objects.rules_engine_condition.admin.edit" & ( isFilter ? ".filter" : "" );
</cfscript>
<cfoutput>
	#renderView( view="/admin/datamanager/_editRecordForm", args={
		  object           = "rules_engine_condition"
		, id               = rc.id      ?: ""
		, record           = prc.record ?: {}
		, editRecordAction = event.buildAdminLink( linkTo='rulesEngine.editConditionAction' )
		, cancelAction     = event.buildAdminLink( linkTo='rulesEngine' )
		, formName         = formName
	} )#
</cfoutput>