<!---@feature admin--->
<cfparam name="prc.categories" type="array" />

<cfoutput>

	<div class="sysconfig-table dataTables_wrapper">

		<div class="well well-sm">
			<div class="dataTables_filter">
				<label>
					<span class="input-icon">
						<input type="text" class="data-table-search" data-global-key="s" autocomplete="off" placeholder="Search settings...">
						<i class="fa fa-search data-table-search-icon"></i>
					</span>
				</label>
			</div>
			<div id="object-listing-table-sysconfig_processing" class="dataTables_processing" style="visibility: hidden;">Processing</div>
			<div class="clearfix"></div>
		</div>

		<ul class="sysconfig_results list-unstyled">
			<cfloop array="#prc.categories#" item="category" index="i">
				<cfset editCategoryUrl = event.buildAdminLink( linkTo='sysconfig.category', queryString='id=#category.getId()#' ) />
				<li class="config-category">
					<a href="#editCategoryUrl#" class="pull-left"><i class="fa fa-fw #translateResource( uri=category.getIcon(), defaultValue='fa-cogs' )# fa-3x"></i></a>&nbsp;
					<div class="pull-left title-and-description">
						<h4>
							<a class="category-title" href="#editCategoryUrl#">
								#translateResource( uri=category.getName(), defaultValue=category.getId() )#
							</a>
						</h4>
						<p class="category-description">#translateResource( uri=category.getDescription(), defaultValue="" )#</p>
					</div>
				</li>
			</cfloop>
		</ul>
	</div>
</cfoutput>