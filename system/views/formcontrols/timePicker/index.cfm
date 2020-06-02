<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	placeholder  = args.placeholder  ?: "";
	defaultValue = args.defaultValue ?: "";

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

	if ( IsDate( value ) ) {
		value = timeFormat( value, "HH:mm" );
	}
</cfscript>

<cfoutput>
	<span class="block input-icon input-icon-right">
		<input name="#inputName#" placeholder="#placeholder#" class="form-control timepicker" id="#inputId#" type="text" value="#HtmlEditFormat( value )#" tabindex="#getNextTabIndex()#" />
		<i class="fa fa-clock-o"></i>
	</span>
</cfoutput>