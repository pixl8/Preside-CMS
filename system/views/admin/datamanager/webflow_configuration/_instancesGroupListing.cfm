<cfscript>
	recordId       = args.recordId              ?: "";
	activeTab      = rc.tab                     ?: "activeInstances"
	instObjName    = args.instanceObjectName    ?: "";
	groupingConfig = args.refGroupingConfig     ?: {};
	webflowId      = groupingConfig.webflowId   ?: "";
	groupedRefs    = groupingConfig.groupedRefs ?: QueryNew( "" );

	event.include( "/js/admin/specific/datamanager/object/");
	event.include( "/css/admin/specific/datamanager/object/");
	event.includeData( {
		  useMultiActions     = false
		, allowSearch         = false
		, isMultilingual      = false
		, objectName          = "webflow_configuration"
		, datasourceUrl       = event.buildAdminLink(
			  linkTo      = "ajaxProxy"
			, queryString = "action=datamanager.webflow_configuration.getInstancesGroupListingForAjaxDataTables&instanceObject=#instObjName#&id=#recordId#&webflowId=#webflowId#&tab=#activeTab#"
		)
	} );
</cfscript>

<cfoutput>
	<cfif Len( webflowId )>
		<div class="table-responsive">
			<table id="object-listing-table-#LCase( args.objectName )#" class="table table-hover object-listing-table">
				<thead>
					<tr>
						<th class="no-sorting" data-field="reference_id">#translateResource( uri="preside-objects.webflow_configuration:instance.group.count.listing.heading.reference_id.label" )#</th>
						<th class="no-sorting" data-field="total_no">#translateResource( uri="preside-objects.webflow_configuration:instance.group.count.listing.heading.total_no.label" )#</th>
						<th>&nbsp;</th>
					</tr>
				</thead>
				<tbody data-nav-list="1" data-nav-list-child-selector="> tr a:nth-of-type(1)">
				</tbody>
			</table>
		</div>
	</cfif>
</cfoutput>