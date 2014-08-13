<cfscript>
	inputName    = args.name        ?: "";
	inputId      = args.id          ?: "";
	placeholder  = args.placeholder ?: "";

	if ( Len( Trim( placeholder ) ) ) {
		placeholder = translateResource( uri=placeholder, defaultValue=placeholder );
	}
</cfscript>

<cfoutput>
	<input type="password" id="#inputId#" placeholder="#placeholder#" name="#inputName#" tabindex="#getNextTabIndex()#">
</cfoutput>