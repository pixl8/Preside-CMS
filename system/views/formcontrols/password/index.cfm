<cfscript>
	inputName    = args.name        ?: "";
	inputId      = args.id          ?: "";
	placeholder  = args.placeholder ?: "";
</cfscript>

<cfoutput>
	<input type="password" id="#inputId#" placeholder="#placeholder#" name="#inputName#" tabindex="#getNextTabIndex()#">
</cfoutput>