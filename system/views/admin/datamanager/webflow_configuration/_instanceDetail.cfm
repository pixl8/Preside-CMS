<cfscript>
	savedState = args.savedState ?: {};
</cfscript>

<cfoutput>
	<!--- TODO saved state render --->
	#SerializeJSON( savedState )#
</cfoutput>