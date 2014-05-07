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
		<li<cfif ancestorIds.findNoCase( menuItems.id )> class="active"</cfif>>
			<a href="#event.buildLink( page=menuItems.id )#">
				#menuItems.title#
			</a>
		</li>
	</cfloop>
</cfoutput>