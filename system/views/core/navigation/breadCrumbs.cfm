<cfset crumbs = event.getBreadCrumbs() />
<cfoutput>
	<cfloop array="#crumbs#" index="i" item="crumb">
		<cfset last = i eq crumbs.len() />

		<li class="<cfif last>active</cfif>">
			<cfif last>
				#crumb.title#
			<cfelse>
				<a href="#crumb.link#">#crumb.title#</a>
			</cfif>
		</li>
	</cfloop>
</cfoutput>