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
	currency 	 = args.args.currency ?: "";

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

	value = HtmlEditFormat( value );
</cfscript>

<cfoutput>
	<cfif len( currency )>
		<span class="block input-sign input-sign-right">
			<input type="text" id="#inputId#" placeholder="#placeholder#" name="#inputName#" value="#value#" class="#inputClass# form-control" min="#minValue#" max="#maxValue#" step="#step#" size="#Len( maxValue )#" tabindex="#getNextTabIndex()#">
			<i class="sign">#currency#</i>
		</span>
		<input type="hidden" value="#currency#">
	<cfelse>
		<input type="text" id="#inputId#" placeholder="#placeholder#" name="#inputName#" value="#value#" class="#inputClass# form-control" min="#minValue#" max="#maxValue#" step="#step#" size="#Len( maxValue )#" tabindex="#getNextTabIndex()#">
	</cfif>
</cfoutput>