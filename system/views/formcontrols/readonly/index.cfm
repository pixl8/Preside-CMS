<cfscript>
	renderer        = args.renderer        ?: "";
	rendererContext = args.rendererContext ?: "readonly";
	value           = args.defaultValue    ?: ( args.savedValue ?: "" );

	if ( len( renderer ) ) {
		value = renderContent( renderer, value, rendererContext );
	}
</cfscript>

<cfoutput><span class="read-only">#( HTMLEditFormat( value ) )#</span></cfoutput>
