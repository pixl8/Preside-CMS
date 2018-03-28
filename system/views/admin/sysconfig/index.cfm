<cfparam name="prc.categories" type="array" />

<cfoutput>
	<ul class="list-unstyled">
		<cfloop array="#prc.categories#" item="category" index="i">
			<cfset editCategoryUrl = event.buildAdminLink( linkTo='sysconfig.category', queryString='id=#category.getId()#' ) />
			<cfset versionHistoryUrl = event.buildAdminLink( linkTo='sysconfig.configHistory', queryString='id=#category.getId()#' ) />
			<li class="config-category">
				<a href="#editCategoryUrl#" class="pull-left"><i class="fa fa-fw #translateResource( uri=category.getIcon(), defaultValue='fa-cogs' )# fa-3x"></i></a>&nbsp;
				<div class="pull-left title-and-description">
					<h4>
						<a href="#editCategoryUrl#">
							#translateResource( uri=category.getName(), defaultValue=category.getId() )#
						</a>
					</h4>
					<p>#translateResource( uri=category.getDescription(), defaultValue="" )#</p>
				</div>
				<a href="#versionHistoryUrl#" class="pull-right">
					<i class="fa fa-fw fa-history"></i>
					#translateResource( "cms:sysconfig.viewHistory.label" )#
				</a>&nbsp; 
			</li>
		</cfloop>
	</ul>
</cfoutput>