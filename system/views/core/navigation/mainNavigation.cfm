<cfscript>
	menuItems = args.menuItems ?: [];

	// Default to Bootstrap class & attributes
	ulNestedClass = args.ulNestedClass ?: 'dropdown-menu'
	liHasKidsClass = args.liHasKidsClass ?: 'dropdown';
	liHasKidsAttributes = args.liHasKidsAttributes ?: '';
	aHasKidsClass = args.aHasKidsClass ?: 'dropdown-toggle';
	aHasKidsAttributes = args.aHasKidsAttributes ?: 'role="button" data-toggle="dropdown" data-target="##"';
	liCurrentClass = args.liCurrentClass ?: 'active';
	aCurrentClass = args.aCurrentClass ?: 'active';
</cfscript>



<cfoutput>
	<cfloop array="#menuItems#" index="i" item="item">
		<li class="<cfif item.active>#liCurrentClass# </cfif><cfif item.children.len()>#liHasKidsClass#</cfif>" #liHasKidsAttributes#>
			<a class="<cfif item.active>#aCurrentClass# </cfif><cfif item.children.len()>#aHasKidsClass#</cfif>" href="#event.buildLink( page=item.id )#" #aHasKidsAttributes#>#item.title#</a>
			<cfif item.children.len()>
				<ul class="#ulNestedClass#" role="menu">
					#renderView( view='/core/navigation/mainNavigation', args={ menuItems=item.children, ulNestedClass=ulNestedClass, liHasKidsClass=liHasKidsClass, liHasKidsAttributes=liHasKidsAttributes, aHasKidsClass=aHasKidsClass, aHasKidsAttributes=aHasKidsAttributes, liCurrentClass=liCurrentClass, aCurrentClass=aCurrentClass } )#
				</ul>
			</cfif>
		</li>
	</cfloop>
</cfoutput>