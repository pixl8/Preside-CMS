
<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	values       = args.values       ?: "";
	defaultValue = args.defaultValue ?: "";
</cfscript>

<cfoutput>
	<input type="hidden" id="#inputId#" name="#inputName#" data-min="0" data-max="#values#" data-step="0.5" data-size="xs" class="#inputClass# rating" tabindex="#getNextTabIndex()#">
</cfoutput>