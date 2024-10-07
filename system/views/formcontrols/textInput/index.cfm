<!---@feature presideForms--->
<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";
	maxlength    = args.maxlength    ?: "";
	minlength    = args.minlength    ?: "";
	disabled     = isTrue( args.disabled ?: "" );
	autocomplete = args.autocomplete ?: "";
	placeholder  = args.placeholder  ?: "";
	placeholder  = HtmlEditFormat( translateResource( uri=placeholder, defaultValue=placeholder ) );

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) ) {
		value = "";
	}

	value = HtmlEditFormat( value );

	htmlAttributes = renderHtmlAttributes(
		  attribs      = ( args.attribs      ?: {} )
		, attribNames  = ( args.attribNames  ?: "" )
		, attribValues = ( args.attribValues ?: "" )
		, attribPrefix = ( args.attribPrefix ?: "" )
	);
</cfscript>

<cfoutput>
	<input type="text" id="#inputId#" placeholder="#placeholder#" name="#inputName#" value="#value#" class="#inputClass# form-control" tabindex="#getNextTabIndex()#"<cfif isNumeric( maxlength ) and maxlength gt 0> maxlength="#maxlength#"</cfif> <cfif isNumeric( minlength ) and minlength gt 0> minlength="#minlength#"</cfif><cfif !isEmptyString( autocomplete )> autocomplete="#autocomplete#"</cfif><cfif disabled> disabled</cfif> #htmlAttributes# />
</cfoutput>
