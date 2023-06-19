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

	value = HtmlEditFormat( value );

	htmlAttributes = renderForHTMLAttributes( htmlAttributeNames=( args.htmlAttributeNames ?: "" ), htmlAttributeValues=( args.htmlAttributeValues ?: "" ), htmlAttributePrefix=( args.htmlAttributePrefix ?: "data-" ) );
</cfscript>

<cfoutput>
	<input type="number" id="#inputId#" class="#inputClass#" name="#inputName#" value="#value#"<cfif isNumeric( minValue )> min="#minValue#"</cfif><cfif isNumeric( maxValue )> max="#maxValue#"</cfif> step="#step#" tabindex="#getNextTabIndex()#" #htmlAttributes# />
</cfoutput>
