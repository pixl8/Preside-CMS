<cfoutput>
	#objectDataTable( objectName="rules_engine_condition", args={
		  allowManageFilter = false // inception!
		, datasourceUrl     = prc.filterDataSourceUrl ?: ""
		, gridFields        = [ "condition_name", "filter_sharing_scope", "owner", "datemodified" ]
		, canDelete         = false
	} )#
</cfoutput>