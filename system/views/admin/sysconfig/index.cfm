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
			#renderView( view="/admin/sysconfig/_results", args={
				  categories = prc.categories
			} )#
		</ul>
	</div>
</cfoutput>