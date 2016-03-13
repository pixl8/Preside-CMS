<cfscript>
	menuItems = args.menuItems ?: [];

	ulNestedClass           = args.ulNestedClass           ?: 'dropdown-menu'
	liCurrentClass          = args.liCurrentClass          ?: 'active';
	liHasChildrenClass      = args.liHasChildrenClass      ?: 'dropdown';
	liHasChildrenAttributes = args.liHasChildrenAttributes ?: '';
	aCurrentClass           = args.aCurrentClass           ?: '';
	aHasChildrenClass       = args.aHasChildrenClass       ?: 'dropdown-toggle';
	aHasChildrenAttributes  = args.aHasChildrenAttributes  ?: 'data-toggle="dropdown"';
</cfscript>

<cfoutput>
	<cfloop array="#menuItems#" index="i" item="item">
		<cfset hasChildren = item.children.len() />
		<li class="<cfif item.active>#liCurrentClass#</cfif><cfif hasChildren> #liHasChildrenClass#</cfif>"<cfif hasChildren> #liHasChildrenAttributes#</cfif>>
			<a class="<cfif item.active>#aCurrentClass#</cfif><cfif hasChildren> #aHasChildrenClass#</cfif>" href="#event.buildLink( page=item.id )#" <cfif hasChildren>#aHasChildrenAttributes#</cfif>>#item.title#<cfif hasChildren> <span class="caret"></span></cfif></a>
			<cfif hasChildren>
				<ul class="#ulNestedClass#">
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