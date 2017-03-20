<cfscript>
	renderer = args.renderer     ?: "";
	context  = args.context      ?: "default";
	value    = args.defaultValue ?: ( args.savedValue ?: "" );

	if ( len( renderer ) ) {
		value = renderContent( renderer, value, context );
	}
</cfscript>

<cfoutput><span class="read-only">#( HTMLEditFormat( value ) )#</span></cfoutput>