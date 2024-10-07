<!---@feature presideForms and assetManager--->
<cfscript>
	inputName      = args.name           ?: "";
	inputId        = args.id             ?: "";
	inputClass     = args.class          ?: "";
	placeholder    = args.placeholder    ?: "";
	defaultValue   = args.defaultValue   ?: "";
	maintainAspect = args.maintainAspect ?: true;

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) ) {
		value = "";
	}

	width  = Val( ListFirst( value, "x" ) );
	height = Val( ListLen( value, "x" ) > 1 ? ListRest( value, "x" ) : "" );
	width  = width  ? width : "";
	height = height ? height : "";

	htmlAttributes = renderHtmlAttributes(
		  attribs      = ( args.attribs      ?: {} )
		, attribNames  = ( args.attribNames  ?: "" )
		, attribValues = ( args.attribValues ?: "" )
		, attribPrefix = ( args.attribPrefix ?: "" )
	);
</cfscript>

<cfoutput>
	<input type="text" id="#inputId#" name="#inputName#" value="#value#" class="#inputClass# image-dimension-picker" tabindex="#getNextTabIndex()#" #htmlAttributes# />
</cfoutput>
