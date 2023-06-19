<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";
	maxlength    = args.maxlength    ?: "";
	placeholder  = args.placeholder  ?: "";
	placeholder  = HtmlEditFormat( translateResource( uri=placeholder, defaultValue=placeholder ) );
	multiple     = isTrue( args.multiple ?: "" );

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) ) {
		value = "";
	}

	value = HtmlEditFormat( value );

	htmlAttributes = renderForHTMLAttributes( htmlAttributeNames=( args.htmlAttributeNames ?: "" ), htmlAttributeValues=( args.htmlAttributeValues ?: "" ), htmlAttributePrefix=( args.htmlAttributePrefix ?: "data-" ) );
</cfscript>

<cfoutput>
	<input type="email" id="#inputId#" placeholder="#placeholder#" multiple="#multiple#" name="#inputName#" value="#value#" class="#inputClass# form-control" tabindex="#getNextTabIndex()#" <cfif isNumeric( maxlength ) and maxlength gt 0> maxlength="#maxlength#"</cfif> #htmlAttributes# />
</cfoutput>
