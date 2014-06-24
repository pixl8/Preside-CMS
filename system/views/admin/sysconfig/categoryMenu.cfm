<cfparam name="args.categories" type="array" />

<cfoutput>
	<cfloop array="#args.categories#" item="category" index="i">
		<li>
			<a href="#event.buildAdminLink( linkTo='sysconfig.category', queryString='id=#category.getId()#' )#">
				<i class="fa fa-angle-double-right"></i>
				#translateResource( uri=category.getName(), defaultValue=category.getId() )#

			</a>
		</li>
	</cfloop>
</cfoutput>