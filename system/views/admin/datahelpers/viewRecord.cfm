<cfscript>
	viewGroups = args.viewGroups ?: [];
</cfscript>

<cfoutput>
	<div class="row">
		<cfloop array="#viewGroups#" item="group" index="i">
			<cfscript>
				groupArgs = args.copy();
				groupArgs.append( group );
			</cfscript>

			#renderViewlet(
				  event = "admin.datahelpers.displayGroup"
				, args  = groupArgs
			)#
		</cfloop>
	</div>
</cfoutput>