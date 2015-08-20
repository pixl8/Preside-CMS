<cfscript>
	inputName    = args.name        ?: "";
	inputId      = args.id          ?: "";
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

	policyMessage = args.policyMessage ?: "";
</cfscript>

<cfoutput>
	<input type="password" id="#inputId#" placeholder="#placeholder#" name="#inputName#" tabindex="#getNextTabIndex()#" value="#value#" class="form-control">
	<cfif Len( Trim( policyMessage ) )>
		<div class="clearfix"></div>
		<br>
		<div class="alert alert-info">#policyMessage#</div>
	</cfif>
</cfoutput>