<cfscript>
	instObjectName = args.instanceObjectName ?: "";
	gridFields     = args.gridFields         ?: [ "owner", "sub_reference", "datecreated" ];
	infoCards      = args.infoCards          ?: "";
</cfscript>

<cfoutput>
	<cfif Len( infoCards )>
		#infoCards#
	</cfif>

	<cfif Len( instObjectName )>
		#objectDataTable( objectName=instObjectName, args={
			  useMultiActions   = false
			, allowManageFilter = false
			, compact           = true
			, gridFields        = gridFields
			, allowSearch       = false
			, allowFilter       = false
		} )#
	</cfif>
</cfoutput>