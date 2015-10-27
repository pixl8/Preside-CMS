<cfscript>
	menuItems = args.menuItems ?: [];

	ulNestedClass           = args.ulNestedClass           ?: 'dropdown-menu'
	liHasChildrenClass      = args.liHasChildrenClass      ?: 'dropdown';
	liHasChildrenAttributes = args.liHasChildrenAttributes ?: '';
	aHasChildrenClass       = args.aHasChildrenClass       ?: 'dropdown-toggle';
	aHasChildrenAttributes  = args.aHasChildrenAttributes  ?: 'role="button" data-toggle="dropdown" data-target="##"';
	liCurrentClass          = args.liCurrentClass          ?: 'active';
	aCurrentClass           = args.aCurrentClass           ?: 'active';
</cfscript>



<cfoutput>
	<cfloop array="#menuItems#" index="i" item="item">
		<li class="<cfif item.active>#liCurrentClass# </cfif><cfif item.children.len()>#liHasChildrenClass#</cfif>" #liHasChildrenAttributes#>
			<a class="<cfif item.active>#aCurrentClass# </cfif><cfif item.children.len()>#aHasChildrenClass#</cfif>" href="#event.buildLink( page=item.id )#" #aHasChildrenAttributes#>#item.title#</a>
			<cfif item.children.len()>
				<ul class="#ulNestedClass#" role="menu">
					#renderView( view='/core/navigation/mainNavigation', args={
						  menuItems               = item.children
						, ulNestedClass           = ulNestedClass
						, liHasChildrenClass      = liHasChildrenClass
						, liHasChildrenAttributes = liHasChildrenAttributes
						, aHasChildrenClass       = aHasChildrenClass
						, aHasChildrenAttributes  = aHasChildrenAttributes
						, liCurrentClass          = liCurrentClass
						, aCurrentClass           = aCurrentClass
					} )#
				</ul>
			</cfif>
		</li>
	</cfloop>
</cfoutput>