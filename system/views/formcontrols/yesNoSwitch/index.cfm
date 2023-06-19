<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) ) {
		value = "";
	}

	checked = IsBoolean( value ) && value;

	htmlAttributes = renderForHTMLAttributes( htmlAttributeNames=( args.htmlAttributeNames ?: "" ), htmlAttributeValues=( args.htmlAttributeValues ?: "" ), htmlAttributePrefix=( args.htmlAttributePrefix ?: "data-" ) );
</cfscript>

<cfoutput>
	<input class="#inputClass# ace ace-switch ace-switch-6" type="checkbox" id="#inputId#" name="#inputName#"<cfif checked> checked="checked"</cfif> value="1" tabindex="#getNextTabIndex()#" #htmlAttributes# />
	<span class="lbl"></span>
</cfoutput>
