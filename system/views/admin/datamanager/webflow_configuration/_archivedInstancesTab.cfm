<cfscript>
	gridFields = args.gridFields ?: [ "owner", "sub_reference", "sub_sub_reference", "archive_reason", "time_taken", "date_started", "date_archived" ];
</cfscript>

<cfoutput>
	#objectDataTable( objectName="cfflow_workflow_archived_instance", args={
		  useMultiActions   = false
		, allowManageFilter = false
		, compact           = true
		, gridFields        = gridFields
	} )#
</cfoutput>