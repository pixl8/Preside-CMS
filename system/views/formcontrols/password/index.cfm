<cfscript>
	inputName   = args.name        ?: "";
	inputId     = args.id          ?: "";
	inputClass  = args.class       ?: "";
	placeholder = args.placeholder ?: "";

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

	if ( IsTrue( args.allowShowHidePassword ?: "" ) ) {
		event.include( "/js/admin/specific/password/" );
		event.include( "/css/admin/specific/password/" );
	}

	passwordPolicyContext = args.passwordPolicyContext ?: "";
</cfscript>

<cfoutput>
	<input type="password" id="#inputId#" placeholder="#placeholder#" name="#inputName#" tabindex="#getNextTabIndex()#" value="#value#" class="#inputClass# form-control"<cfif Len( Trim( passwordPolicyContext ) )> data-password-policy-context="#passwordPolicyContext#"</cfif>>
	<cfif IsTrue( args.allowShowHidePassword ?: "" )>
		<a href="###inputId#" class="fa fa-fw fa-eye toggle-password" title="#translateResource( 'cms:help.popover.title' )#" data-rel="popover" data-trigger="hover" data-placement="left" data-content="#translateResource( 'cms:help.password_reveal.title' )#"></a>
	</cfif>
</cfoutput>