<cfscript>
	renderer        = args.renderer        ?: "";
	rendererContext = args.rendererContext ?: "readonly";
	value           = args.defaultValue    ?: ( args.savedValue ?: "" );

	if ( len( renderer ) ) {
		value = renderContent( renderer, value, rendererContext );
	}

	htmlAttributes = renderForHTMLAttributes( htmlAttributeNames=( args.htmlAttributeNames ?: "" ), htmlAttributeValues=( args.htmlAttributeValues ?: "" ), htmlAttributePrefix=( args.htmlAttributePrefix ?: "data-" ) );
</cfscript>

<cfoutput><span class="read-only" #htmlAttributes#>#( HTMLEditFormat( value ) )#</span></cfoutput>
