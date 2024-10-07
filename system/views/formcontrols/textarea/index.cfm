<!---@feature presideForms--->
<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	placeholder  = args.placeholder  ?: "";
	placeholder  = HtmlEditFormat( translateResource( uri=placeholder, defaultValue=placeholder ) );
	defaultValue = args.defaultValue ?: "";
	maxlength    = args.maxlength    ?: "";
	minlength    = args.minlength    ?: "";

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
	<textarea id="#inputId#" placeholder="#placeholder#" name="#inputName#" class="#inputClass# form-control autosize-transition<cfif isNumeric( maxlength ) and maxlength gt 0> limited</cfif>"<cfif isNumeric( maxlength ) and maxlength gt 0> data-maxlength="#maxLength#"</cfif> <cfif isNumeric( minlength ) and minlength gt 0> minlength="#minlength#"</cfif> tabindex="#getNextTabIndex()#" #htmlAttributes#>#value#</textarea>
</cfoutput>
