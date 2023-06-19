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

	htmlAttributes = renderForHTMLAttributes( htmlAttributeNames=( args.htmlAttributeNames ?: "" ), htmlAttributeValues=( args.htmlAttributeValues ?: "" ), htmlAttributePrefix=( args.htmlAttributePrefix ?: "data-" ) );
</cfscript>

<cfoutput>
	<input type="text" id="#inputId#" name="#inputName#" value="#value#" class="#inputClass# image-dimension-picker" tabindex="#getNextTabIndex()#" #htmlAttributes# />
</cfoutput>
