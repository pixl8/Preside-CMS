<!---@feature presideForms--->
<cfscript>
	renderer        = args.renderer        ?: "";
	rendererContext = args.rendererContext ?: "readonly";
	value           = args.defaultValue    ?: ( args.savedValue ?: "" );

	if ( len( renderer ) ) {
		value = renderContent( renderer, value, rendererContext );
	}

	htmlAttributes = renderHtmlAttributes(
		  attribs      = ( args.attribs      ?: {} )
		, attribNames  = ( args.attribNames  ?: "" )
		, attribValues = ( args.attribValues ?: "" )
		, attribPrefix = ( args.attribPrefix ?: "" )
	);
</cfscript>

<cfoutput><span class="read-only" #htmlAttributes#>#( HTMLEditFormat( value ) )#</span></cfoutput>
