<cfscript>
	instObjectName = args.instanceObjectName ?: "";
	gridFields     = args.gridFields         ?: [ "owner", "sub_reference", "datecreated" ];
</cfscript>

<cfoutput>
	<cfif Len( instObjectName )>
		#objectDataTable( objectName=instObjectName, args={
			  useMultiActions   = false
			, allowManageFilter = false
			, compact           = true
			, gridFields        = gridFields
		} )#
	</cfif>
</cfoutput>