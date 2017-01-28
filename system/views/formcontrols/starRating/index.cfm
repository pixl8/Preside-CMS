<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";
	value        = rc[ inputName ]   ?: 0;

	starCount = Val( args.starCount ?: "5" );
	step      = IsTrue( args.allowHalfStars ?: "" ) ? 0.5 : 1;

	value  = rc[ inputName ] ?: defaultValue;
	if ( !IsSimpleValue( value ) ) {
		value = "";
	}

	value = Val( value );
</cfscript>

<cfoutput>
	<input type="hidden" id="#inputId#" name="#inputName#" data-min="0" data-max="#starCount#" data-step="#step#" data-size="xs" class="#inputClass# rating" tabindex="#getNextTabIndex()#" value="#value#">
</cfoutput>