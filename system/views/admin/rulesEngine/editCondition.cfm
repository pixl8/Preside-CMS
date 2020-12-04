<cfscript>
	isFilter    = Len( Trim( prc.record.filter_object ?: "" ) );
	isNonGlobal = Len( Trim( prc.record.owner ?: "" ) );
	formName    = "preside-objects.rules_engine_condition.admin.edit" & ( isFilter ? ".filter" : "" );
	editAction  = event.buildAdminLink( linkTo='rulesEngine.editConditionAction' );

	if ( isFilter ) {
		event.include( "/js/admin/specific/saveFilterForm/" );
	}
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_editRecordForm", args={
		  object           = "rules_engine_condition"
		, id               = rc.id      ?: ""
		, record           = prc.record ?: {}
		, editRecordAction = editAction
		, cancelAction     = event.buildAdminLink( linkTo='rulesEngine' )
		, formName         = formName
		, additionalArgs   = additionalArgs ?: {}
	} )#
</cfoutput>