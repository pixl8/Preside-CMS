<!---@feature presideForms--->
<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";
	maxlength    = args.maxlength    ?: "";
	placeholder  = args.placeholder  ?: "";
	placeholder  = EncodeForHtmlAttribute( translateResource( uri=placeholder, defaultValue=placeholder ) );
	multiple     = isTrue( args.multiple ?: "" );
	inputType    = multiple ? "text" : "email";

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) ) {
		value = "";
	}

	value = EncodeForHtmlAttribute( value );

	htmlAttributes = renderHtmlAttributes(
		  attribs      = ( args.attribs      ?: {} )
		, attribNames  = ( args.attribNames  ?: "" )
		, attribValues = ( args.attribValues ?: "" )
		, attribPrefix = ( args.attribPrefix ?: "" )
	);
</cfscript>

<cfoutput>
	<input type="#inputType#" id="#inputId#" placeholder="#placeholder#" name="#inputName#" value="#value#" class="#inputClass# form-control" tabindex="#getNextTabIndex()#" <cfif isNumeric( maxlength ) and maxlength gt 0> maxlength="#maxlength#"</cfif><cfif multiple> multiple</cfif> #htmlAttributes# />
</cfoutput>
