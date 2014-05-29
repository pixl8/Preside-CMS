<cfscript>
	param name="args.icon"           type="string";
	param name="args.title"          type="string";
	param name="args.savedPerms"     type="array";
	param name="args.inheritedPerms" type="array";
	param name="args.savedOpposites" type="array";
</cfscript>

<cfoutput>
	<p>
		<i class="fa fa-#args.icon#" title="#args.title#"></i>

		<cfif ( args.inheritedPerms.len() + args.savedPerms.len() )>
			<cfloop array="#args.inheritedPerms#" index="i" item="perm">
				<span class="inherited-perm<cfif args.savedOpposites.find( perm )> overrided</cfif>">
					#perm.name#</span><cfif i lt args.inheritedPerms.len() || args.savedPerms.len()><span class="inherited-perm">,</span></cfif>
			</cfloop>
			<cfloop array="#args.savedPerms#" index="i" item="perm">
				<span class="selected-perm">#perm.name#<cfif i lt args.savedPerms.len()>,</cfif></span>
			</cfloop>
		<cfelse>
			<span class="no-perms">#translateResource( "cms:contextperms.no.groups" )#</span>
		</cfif>
	</p>
</cfoutput>