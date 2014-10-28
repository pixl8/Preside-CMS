<cfscript>
	menuItems = args.menuItems ?: [];
</cfscript>

<cfoutput>
	<cfloop array="#menuItems#" item="item">
		<li class="<cfif item.active>active </cfif><cfif item.children.len()>has-submenu</cfif>">
			<a href="#event.buildLink( page=item.id )#">#item.title#</a>
			<cfif item.children.len()>
				<ul class="submenu">
					#renderView( view="/core/navigation/subNavigation", args={ menuItems=item.children } )#
				</ul>
			</cfif>
		</li>
	</cfloop>
</cfoutput>