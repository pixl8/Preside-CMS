<!---@feature admin and customFields--->
<cfscript>
	fieldId = args.fieldId ?: "";
</cfscript>

<cfoutput>
	#objectDataTable( objectName="custom_field_lookup", args={
		  compact            = true
		, allowFilter        = false
		, allowDataExport    = false
		, allowSavedViews    = false
		, useMultiActions    = true
		, field              = fieldId
		, listingContextKey  = "custom_field_lookup_#fieldId#"
	} )#
	<p class="text-center">
		<a href="#event.buildAdminLink( objectName="custom_field_lookup", operation="addRecord", queryString="field=#fieldId#" )#" class="btn btn-primary">
			<i class="fa fa-fw fa-plus"></i> #translateResource( "preside-objects.custom_field:add.lookup.btn" )#
		</a>
	</p>
</cfoutput>
