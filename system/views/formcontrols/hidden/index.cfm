<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) ) {
		value = "";
	}

	htmlAttributes = renderForHTMLAttributes( htmlAttributeNames=( args.htmlAttributeNames ?: "" ), htmlAttributeValues=( args.htmlAttributeValues ?: "" ), htmlAttributePrefix=( args.htmlAttributePrefix ?: "data-" ) );
</cfscript>

<cfoutput>
	<input type="hidden" class="#inputClass#" id="#inputId#" name="#inputName#" value="#HtmlEditFormat( value )#" #htmlAttributes# />
</cfoutput>
