<cfscript>
// writeDump(args);abort;
	inputName    = args.name          ?: "";
	inputId      = args.id            ?: "";
	inputClass   = args.class         ?: "";
	placeholder  = args.placeholder   ?: "";
	defaultValue = args.defaultValue  ?: "";
	minValue     = Val( args.minValue ?: 0 );
	maxValue     = args.maxValue      ?: "";
	step         = Val( args.step     ?: 1 );

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

	value = HtmlEditFormat( value );
</cfscript>

<cfoutput>
	<input type="text" id="#inputId#" placeholder="#placeholder#" name="#inputName#" value="#value#" class="#inputClass# form-control number" min="#minValue#" max="#maxValue#" step="#step#" size="#Len( maxValue )#" tabindex="#getNextTabIndex()#">
</cfoutput>