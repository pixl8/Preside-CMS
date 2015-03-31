<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	defaultValue = args.defaultValue ?: "";
	placeholder  = args.placeholder  ?: "";
	placeholder = HtmlEditFormat( translateResource( uri=placeholder, defaultValue=placeholder ) );
</cfscript>

<cfoutput>
	<input type="file" id="#inputId#" placeholder="#placeholder#" name="#inputName#" class="" tabindex="#getNextTabIndex()#">
</cfoutput>