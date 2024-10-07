<!---@feature presideForms--->
<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";
	disabled     = isTrue( args.disabled ?: "" );

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) ) {
		value = "";
	}

	checked = IsBoolean( value ) && value;

	htmlAttributes = renderHtmlAttributes(
		  attribs      = ( args.attribs      ?: {} )
		, attribNames  = ( args.attribNames  ?: "" )
		, attribValues = ( args.attribValues ?: "" )
		, attribPrefix = ( args.attribPrefix ?: "" )
	);
</cfscript>

<cfoutput>
	<input class="#inputClass# ace ace-switch ace-switch-6" type="checkbox" id="#inputId#" name="#inputName#"<cfif checked> checked="checked"</cfif> value="1" tabindex="#getNextTabIndex()#" <cfif disabled> disabled</cfif> #htmlAttributes#>
	<span class="lbl"></span>
</cfoutput>
