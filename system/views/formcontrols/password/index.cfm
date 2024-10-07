<!---@feature presideForms--->
<cfscript>
	inputName    = args.name        ?: "";
	inputId      = args.id          ?: "";
	inputClass   = args.class       ?: "";
	placeholder  = args.placeholder ?: "";
	newPassword  = isTrue( args.newPassword ?: false );

	if ( Len( Trim( placeholder ) ) ) {
		placeholder = translateResource( uri=placeholder, defaultValue=placeholder );
	}

	if ( IsTrue( args.outputSavedValue ?: "" ) ) {
		defaultValue = args.defaultValue ?: "";
		value        = event.getValue( name=inputName, defaultValue=defaultValue );
		if ( !IsSimpleValue( value ) ) {
			value = "";
		}
		value = HtmlEditFormat( value );
	} else {
		value = "";
	}

	passwordPolicyContext = args.passwordPolicyContext ?: "";

	htmlAttributes = renderHtmlAttributes(
		  attribs      = ( args.attribs      ?: {} )
		, attribNames  = ( args.attribNames  ?: "" )
		, attribValues = ( args.attribValues ?: "" )
		, attribPrefix = ( args.attribPrefix ?: "" )
	);
</cfscript>

<cfoutput>
	<input type="password" id="#inputId#" placeholder="#placeholder#" name="#inputName#" tabindex="#getNextTabIndex()#" value="#value#" class="#inputClass# form-control"<cfif Len( Trim( passwordPolicyContext ) )> data-password-policy-context="#passwordPolicyContext#"</cfif><cfif isTrue( newPassword )> autocomplete="new-password"</cfif> #htmlAttributes# />
</cfoutput>
