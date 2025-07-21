<cfscript>
	printedState  = args.printedState ?: "";
	hasPermission = isTrue( args.hasPermission ?: hasCmsPermission( "webflows.admin.viewSavedState" ) );
</cfscript>

<cfoutput>
	<cfif hasPermission && Len( printedState )>
		<pre>#printedState#</pre>
	</cfif>
</cfoutput>