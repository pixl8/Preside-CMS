
<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	values       = args.values       ?: "";
	defaultValue = args.defaultValue ?: "";

	if(args.halfStar) {
		halfStar = 0.5;
	} else {
		halfStar = 1;
	}
	
</cfscript>

<cfoutput>
	<input type="hidden" id="#inputId#" name="#inputName#" data-min="0" data-max="#values#" data-step="#halfStar#" data-size="xs" class="#inputClass# rating" tabindex="#getNextTabIndex()#">
</cfoutput>