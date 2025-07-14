<cfscript>
	ignoreKeys   = args.ignoreKeys   ?: [ "_rurl", "_wid" ];
	printedState = args.printedState ?: "";
	isSystemUser = isTrue( args.isSystemUser ?: "" );
	naLabel      = translateResource( uri="cms:not.applicable" );
</cfscript>

<cfoutput>
	<cfif isSystemUser && Len( printedState )>
		<pre>#printedState#</pre>
	</cfif>
</cfoutput>