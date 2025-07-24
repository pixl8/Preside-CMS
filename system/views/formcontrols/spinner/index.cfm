<!---@feature presideForms--->
<cfscript>
	inputName    = args.name          ?: "";
	inputId      = args.id            ?: "";
	inputClass   = args.class         ?: "";
	placeholder  = args.placeholder   ?: "";
	defaultValue = args.defaultValue  ?: "";
	minValue     = args.minValue      ?: "";
	maxValue     = args.maxValue      ?: "";
	step         = Val( args.step     ?: 1 );

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
	<input type="number" id="#inputId#" class="form-control #inputClass#" name="#inputName#" value="#value#"<cfif isNumeric( minValue )> min="#minValue#"</cfif><cfif isNumeric( maxValue )> max="#maxValue#"</cfif><cfif Len( Trim( placeholder ) )> placeholder="#EncodeForHTMLAttribute( placeholder )#"</cfif> step="#step#" tabindex="#getNextTabIndex()#" #htmlAttributes# />
</cfoutput>
