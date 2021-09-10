<cfparam name="args.categories" type="array"/>
<cfoutput>
	<cfloop array="#args.categories#" item="category" index="i">
		<cfset editCategoryUrl = event.buildAdminLink( linkTo='sysconfig.category', queryString='id=#category.getId()#' ) />
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
		</li>
	</cfloop>
</cfoutput>