<cfscript>
	gridFields = args.gridFields ?: [ "owner", "sub_reference", "sub_sub_reference", "datecreated" ];
</cfscript>

<cfoutput>
	#objectDataTable( objectName="cfflow_workflow_instance", args={
		  useMultiActions   = false
		, allowManageFilter = false
		, compact           = true
		, gridFields        = gridFields
	} )#
</cfoutput>