<cfscript>
	inputName    = args.name        ?: "";
	inputId      = args.id          ?: "";
	inputClass   = args.class       ?: "";
	placeholder  = args.placeholder ?: "";

	if ( Len( Trim( placeholder ) ) ) {
		placeholder = translateResource( uri=placeholder, defaultValue=placeholder );
	}

	if ( IsTrue( args.outputSavedValue ?: "" ) ) {
		defaultValue = args.defaultValue ?: "";
		value  = event.getValue( name=inputName, defaultValue=defaultValue );
		if ( not IsSimpleValue( value ) ) {
			value = "";
		}
		value = HtmlEditFormat( value );
	} else {
		value = "";
	}

	passwordPolicyContext = args.passwordPolicyContext ?: "";
</cfscript>

<cfoutput>
	<input type="password" id="#inputId#" placeholder="#placeholder#" name="#inputName#" tabindex="#getNextTabIndex()#" value="#value#" class="#inputClass# form-control"<cfif Len( Trim( passwordPolicyContext ) )> data-password-policy-context="#passwordPolicyContext#"</cfif>>
</cfoutput>