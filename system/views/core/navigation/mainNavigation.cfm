<cfscript>
	menuItems = args.menuItems ?: [];
</cfscript>

<cfoutput>
	<cfloop array="#menuItems#" index="i" item="item">
		<li class="<cfif item.active>active </cfif><cfif item.children.len()>dropdown</cfif>">
			<a href="#event.buildLink( page=item.id )#"<cfif item.children.len()> class="dropdown-toggle"</cfif>>#item.title#</a>
			<cfif item.children.len()>
				<ul class="dropdown-menu" role="menu">
					#renderView( view='/core/navigation/mainNavigation', args={ menuItems=item.children } )#
				</ul>
			</cfif>
		</li>
	</cfloop>
</cfoutput>