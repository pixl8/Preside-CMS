<!---@feature admin and customObjects--->
<cfscript>
	targetObject = args.targetObject ?: "";
	fieldCount   = Val( args.fieldCount ?: 0 );
	addFieldLink = event.buildAdminLink(
		  objectName  = "custom_field"
		, operation   = "addRecord"
		, queryString = "target_object=#targetObject#"
	);
	sortFieldsLink = event.buildAdminLink(
		  objectName  = "custom_field"
		, operation   = "sortRecords"
		, queryString = "target_object=#targetObject#"
	);
</cfscript>

<cfoutput>
	<cfif fieldCount>
		#objectDataTable( objectName="custom_field", args={
			  compact           = true
			, allowFilter       = false
			, allowDataExport   = false
			, allowSavedViews   = false
			, useMultiActions   = true
			, gridFields        = [ "label", "kind", "data_type", "active", "datemodified" ]
			, target_object     = targetObject
			, listingContextKey = "custom_object_fields_#targetObject#"
			, datasourceUrl     = event.buildAdminLink(
				  objectName = "custom_field"
				, operation  = "ajaxListing"
				, args       = { target_object=targetObject, useMultiActions=true }
			  )
		} )#
	<cfelse>
		<p class="text-center light-grey"><em>#translateResource( "preside-objects.custom_object:viewtab.fields.empty" )#</em></p>
	</cfif>
	<p class="text-center">
		<cfif fieldCount gt 1>
			<a href="#sortFieldsLink#" class="btn btn-info">
				<i class="fa fa-fw fa-sort-amount-asc"></i> #translateResource( "preside-objects.custom_object:viewtab.fields.sort.btn" )#
			</a>
			&nbsp;
		</cfif>
		<a href="#addFieldLink#" class="btn btn-primary">
			<i class="fa fa-fw fa-plus"></i> #translateResource( "preside-objects.custom_object:viewtab.fields.add.btn" )#
		</a>
	</p>
</cfoutput>
