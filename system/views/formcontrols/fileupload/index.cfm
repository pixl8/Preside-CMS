<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";
	accept       = args.accept       ?: "";
	placeholder  = args.placeholder  ?: "";
	placeholder = HtmlEditFormat( translateResource( uri=placeholder, defaultValue=placeholder ) );
</cfscript>

<cfoutput>
	<input type="file" id="#inputId#" class="#inputClass#" placeholder="#placeholder#" name="#inputName#" tabindex="#getNextTabIndex()#"<cfif Len( Trim( accept ) )> accept="#accept#"</cfif>>
</cfoutput>