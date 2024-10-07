<!---@feature admin--->
<cfscript>
	topRightButtons        = prc.topRightButtons ?: "";
	useSegmentationFilters = IsTrue( prc.useSegmentationFilters ?: "" );
	datatable              = objectDataTable( objectName="rules_engine_condition", args={
		  allowManageFilter = false // inception!
		, allowFilter       = false
		, allowDataExport   = false
		, usesTreeView      = false
		, gridFields        = [ "condition_name", "is_favourite", "filter_folder", "filter_sharing_scope", "owner", "datemodified" ]
		, compact           = true
		, canDelete         = false
	} );

	activeTab = rc.tab ?: "";
</cfscript>
<cfoutput>
	<cfif topRightButtons.len()>
		<div class="top-right-button-group">#topRightButtons#</div>
	</cfif>

	<cfif useSegmentationFilters>
		<div class="tabbable">
			<ul class="nav nav-tabs">
				<li<cfif activeTab neq "segmentation"> class="active"</cfif>>
					<a href="##tab-datatable" data-toggle="tab">
						<i class="fa fa-fw fa-filter"></i>&nbsp;

						#translateResource( "cms:datamanager.managefilters.plain.tab.title")#
					</a>
				</li>
				<li<cfif activeTab eq "segmentation"> class="active"</cfif>>
					<a href="##tab-segmentation" data-toggle="tab">
						<i class="fa fa-fw fa-sitemap"></i>&nbsp;

						#translateResource( "cms:datamanager.managefilters.segmentation.tab.title")#
					</a>
				</li>
			</ul>
			<div class="tab-content">
				<div class="tab-pane<cfif activeTab neq "segmentation"> active</cfif>" id="tab-datatable">
					#datatable#
				</div>
				<div class="tab-pane<cfif activeTab eq "segmentation"> active</cfif>" id="tab-segmentation">
					#renderViewlet( event="admin.datamanager.manageSegmentationFilters", args=args )#
				</div>
			</div>
		</div>
	<cfelse>
		#datatable#
	</cfif>
</cfoutput>