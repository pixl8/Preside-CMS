<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	defaultValue = args.defaultValue ?: "";

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

	checked = IsBoolean( value ) and value;
</cfscript>

<cfoutput>
	<input class="ace ace-switch ace-switch-5" type="checkbox" id="#inputId#" name="#inputName#"<cfif checked> checked="checked"</cfif> value="1" tabindex="#getNextTabIndex()#">
	<span class="lbl"></span>
</cfoutput>