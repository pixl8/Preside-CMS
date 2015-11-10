<cfscript>
	menuItems = args.menuItems ?: [];

	// Default classes and attributes for sub navigaion
	ulNestedClass       = args.ulNestedClass       ?: 'submenu'
	liHasKidsClass      = args.liHasKidsClass      ?: 'hasSubmenu';
	liHasKidsAttributes = args.liHasKidsAttributes ?: '';
	aHasKidsClass       = args.aHasKidsClass       ?: 'dropdown-toggle';
	aHasKidsAttributes  = args.aHasKidsAttributes  ?: 'role="button" data-toggle="dropdown" data-target="##"';
	liCurrentClass      = args.liCurrentClass      ?: 'active';
	aCurrentClass       = args.aCurrentClass       ?: 'active';

</cfscript>

<cfoutput>
	<cfloop array="#menuItems#" item="item">
		<cfset hasChildren = item.children.len() />
		<li class="<cfif item.active>#liCurrentClass# </cfif> <cfif hasChildren>#liHasKidsClass#</cfif>" <cfif hasChildren> #liHasKidsAttributes# </cfif> >
			<a class="<cfif item.active>#aCurrentClass# </cfif> <cfif hasChildren>#aHasKidsClass#</cfif>" href="#event.buildLink( page=item.id )#" <cfif hasChildren> #aHasKidsAttributes# </cfif> > #item.title#</a>
			<cfif hasChildren>
				<ul class="#ulNestedClass#">
					#renderView( view='/core/navigation/subNavigation', args={
					           menuItems          = item.children
					        , ulNestedClass       = ulNestedClass
					        , liHasKidsClass      = liHasKidsClass
					        , liHasKidsAttributes = liHasKidsAttributes
					        , aHasKidsClass       = aHasKidsClass
					        , aHasKidsAttributes  = aHasKidsAttributes
					        , liCurrentClass      = liCurrentClass
					        , aCurrentClass       = aCurrentClass
					} )#
				</ul>
			</cfif>
		</li>
	</cfloop>
</cfoutput>