<cfparam name="args.categories" type="array" />

<cfoutput>
	<cfloop array="#args.categories#" item="category" index="i">
		#renderView( view="/admin/layout/sidebar/_subMenuItem", args={
			  link  = event.buildAdminLink( linkTo='sysconfig.category', queryString='id=' & category.getId() )
			, title = translateResource( uri=category.getName(), defaultValue=category.getId() )
		} )#
	</cfloop>
</cfoutput>