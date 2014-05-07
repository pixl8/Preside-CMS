<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	placeholder  = args.placeholder  ?: "";
	defaultValue = args.defaultValue ?: "";
	minValue     = Val( args.minValue ?: 0 );
	maxValue     = Val( args.maxValue ?: 999 );
	step         = Val( args.step     ?: 1 );

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}
</cfscript>

<cfoutput>
	<input type="text" id="#inputId#" name="#inputName#" value="#value#" class="spinner-input" data-min="#minValue#" data-max="#maxValue#" data-step="#step#" maxlength="#Len( maxValue )#" tabindex="#getNextTabIndex()#">
</cfoutput>