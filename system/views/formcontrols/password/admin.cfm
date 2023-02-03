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
	}

	passwordPolicyContext = args.passwordPolicyContext ?: "";
</cfscript>

<cfoutput>
	<cfif IsTrue( args.allowShowHidePassword ?: "" )>
		<span class="block input-icon input-icon-right">
	</cfif>

		<input type="password" id="#inputId#" placeholder="#placeholder#" name="#inputName#" tabindex="#getNextTabIndex()#" value="#value#" class="#inputClass# form-control"<cfif Len( Trim( passwordPolicyContext ) )> data-password-policy-context="#passwordPolicyContext#"</cfif><cfif isTrue( newPassword )> autocomplete="new-password"</cfif>>
		<cfif IsTrue( args.allowShowHidePassword ?: "" )>
			<i data-target="###inputId#" class="fa fa-fw fa-eye toggle-password" title="#translateResource( 'cms:help.popover.title' )#" data-rel="popover" data-trigger="hover" data-placement="left" data-content="#translateResource( 'cms:help.password_reveal.title' )#"></i>
		</cfif>

	<cfif IsTrue( args.allowShowHidePassword ?: "" )>
		</span>
	</cfif>
</cfoutput>