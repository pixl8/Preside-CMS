<cfscript>
	menuItems   = args.menuItems ?: [];
</cfscript>

<cfoutput>
	<cfloop array="#menuItems#" index="i" item="item">
		<li<cfif item.active> class="active"</cfif>>
			<a href="#event.buildLink( page=item.id )#">#item.title#</a>
			<!-- TODO, build children -->
		</li>
	</cfloop>
</cfoutput>