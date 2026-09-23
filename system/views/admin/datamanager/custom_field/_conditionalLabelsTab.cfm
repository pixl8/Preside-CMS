<!---@feature admin and customFields and rulesEngine--->
<cfscript>
	fieldId = args.fieldId ?: "";
</cfscript>

<cfoutput>
	#objectDataTable( objectName="custom_field_conditional_rule", args={
		  compact            = true
		, allowFilter        = false
		, allowDataExport    = false
		, allowSavedViews    = false
		, useMultiActions    = true
		, field              = fieldId
		, listingContextKey  = "custom_field_conditional_rule_#fieldId#"
		, hiddenGridFields   = [ "colour" ]
		, sortableFields     = [ "sort_order" ]
	} )#
	<p class="text-center">
		<a href="#event.buildAdminLink( objectName="custom_field_conditional_rule", operation="sortRecords", queryString="field=#fieldId#" )#" class="btn btn-info">
			<i class="fa fa-fw fa-sort-amount-asc"></i> #translateResource( uri="cms:datamanager.sortRecords.link" )#
		</a>
		<a href="#event.buildAdminLink( objectName="custom_field_conditional_rule", operation="addRecord", queryString="field=#fieldId#" )#" class="btn btn-primary">
			<i class="fa fa-fw fa-plus"></i> #translateResource( "preside-objects.custom_field:add.conditional_label.btn" )#
		</a>
	</p>
</cfoutput>
