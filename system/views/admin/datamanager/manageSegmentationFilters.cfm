<!---@feature admin--->
<cfscript>
	hasAnyFilters = isTrue( args.hasAnyFilters ?: "" );
	objectName    = rc.object ?: "";
</cfscript>
<cfoutput>
	<p class="alert alert-info">
		<i class="fa fa-fw fa-info-circle"></i>
		#translateResource( "cms:datamanager.managefilters.segmentation.filters.expo" )#
	</p>

	<cfif hasAnyFilters>
		#objectDataTable( objectName="rules_engine_condition", args={
			  usesTreeView = true
			, treeOnly     = true
			, gridFields   = [ "condition_name", "segmentation_last_count", "segmentation_last_calculation", "segmentation_last_time_taken" ]
		} )#
	<cfelse>
		<p class="alert alert-warning">
			<i class="fa fa-fw fa-exclamation-triangle"></i>
			#translateResource( "cms:datamanager.managefilters.no.segmentation.filters.info" )#
		</p>
	</cfif>

	<p class="text-center">
		<a class="btn btn-success" href="#event.buildAdminLink( linkto='datamanager.addSegmentationFilter', queryString='object=#objectName#' )#">
			<i class="fa fa-fw fa-plus"></i>
			#translateResource( "cms:datamanager.managefilters.add.segmentation.filter.btn" )#
		</a>
	</p>
</cfoutput>