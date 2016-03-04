<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";

	starCount = Val( args.starCount ?: "5" );
	step      = IsTrue( args.allowHalfStars ?: "" ) ? 0.5 : 1;
</cfscript>

<cfoutput>
	<input type="hidden" id="#inputId#" name="#inputName#" data-min="0" data-max="#starCount#" data-step="#step#" data-size="xs" class="#inputClass# rating" tabindex="#getNextTabIndex()#">
</cfoutput>