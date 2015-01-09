<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	placeholder  = args.placeholder  ?: "";
	placeholder = HtmlEditFormat( translateResource( uri=placeholder, defaultValue=placeholder ) );
	defaultValue = args.defaultValue ?: "";
	maxLength    = Val( args.maxLength ?: 0 );

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

	value = HtmlEditFormat( value );
</cfscript>

<cfoutput>
	<textarea id="#inputId#" placeholder="#placeholder#" name="#inputName#" class="form-control autosize-transition<cfif maxLength> limited</cfif>"<cfif maxLength> data-maxlength="#maxLength#"</cfif> tabindex="#getNextTabIndex()#">#value#</textarea>
</cfoutput>