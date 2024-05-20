<!---@feature presideForms--->
<cfscript>
	inputName     = args.name          ?: "";
	inputId       = args.id            ?: "";
	inputClass    = args.class         ?: "";
	placeholder   = args.placeholder   ?: "";
	defaultValue  = args.defaultValue  ?: "";
	basedOn       = args.basedOn       ?: "label";
	slugDelimiter = args.slugDelimiter ?: "-";

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) ) {
		value = "";
	}

	htmlAttributes = renderHtmlAttributes(
		  attribs      = ( args.attribs      ?: {} )
		, attribNames  = ( args.attribNames  ?: "" )
		, attribValues = ( args.attribValues ?: "" )
		, attribPrefix = ( args.attribPrefix ?: "" )
	);
</cfscript>

<cfoutput>
	<input type="text" class="#inputClass# auto-slug form-control" id="#inputId#" placeholder="#placeholder#" name="#inputName#" value="#HtmlEditFormat( value )#" data-based-on="#basedOn#" data-slug-delimiter="#slugDelimiter#" tabindex="#getNextTabIndex()#" #htmlAttributes# />
</cfoutput>
