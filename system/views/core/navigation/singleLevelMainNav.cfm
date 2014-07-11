<cfscript>
	menuItems   = args.menuItems ?: QueryNew('');
	ancestorIds = event.getPageProperty(
		  propertyName  = "id"
		, defaultValue  = []
		, cascading     = true
		, cascadeMethod = "collect"
	);
</cfscript>

<cfoutput>
	<cfloop query="menuItems">
		<cfif not menuItems.exclude_from_navigation>
			<li<cfif ancestorIds.findNoCase( menuItems.id )> class="active"</cfif>>
				<a href="#event.buildLink( page=menuItems.id )#">
					#( Len( Trim( menuItems.navigation_title ) ) ? menuItems.navigation_title : menuItems.label )#
				</a>
			</li>
		</cfif>
	</cfloop>
</cfoutput>