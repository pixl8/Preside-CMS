<cfscript>
	ignoreKeys    = args.ignoreKeys   ?: [ "_rurl", "_wid" ];
	printedState  = args.printedState ?: "";
	hasPermission = isTrue( args.hasPermission ?: hasCmsPermission( "webflows.admin.viewSavedState" ) );
	naLabel       = translateResource( uri="cms:not.applicable" );
</cfscript>

<cfoutput>
	<cfif hasPermission && Len( printedState )>
		<pre>#printedState#</pre>
	</cfif>
</cfoutput>