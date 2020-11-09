<cfoutput>
	#objectDataTable( objectName="rules_engine_condition", args={
		  allowManageFilter = false // inception!
		, gridFields        = [ "condition_name", "filter_sharing_scope", "owner", "datemodified" ]
		, canDelete         = false
	} )#
</cfoutput>