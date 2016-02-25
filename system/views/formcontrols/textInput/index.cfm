<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	defaultValue = args.defaultValue ?: "";
	placeholder  = args.placeholder  ?: "";
	placeholder = HtmlEditFormat( translateResource( uri=placeholder, defaultValue=placeholder ) );

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

	value = HtmlEditFormat( value );
</cfscript>

<cfoutput>
	<input type="text" id="#inputId#" placeholder="#placeholder#" name="#inputName#" value="#value#" class="form-control" tabindex="#getNextTabIndex()#">
</cfoutput>