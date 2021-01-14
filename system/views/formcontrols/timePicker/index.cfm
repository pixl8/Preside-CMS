<cfscript>
	inputName      = args.name         ?: "";
	inputId        = args.id           ?: "";
	placeholder    = args.placeholder  ?: "";
	defaultValue   = args.defaultValue ?: "";
	defaultTime    = args.defaultTime  ?: "";

	defaultHour    = 0;
	defaultMinutes = 0;
	if ( defaultTime == "now" ) {
		defaultHour    = hour( now() );
		defaultMinutes = minute( now() );
	} else if ( len( defaultTime ) ) {
		defaultHour    = val( listFirst( defaultTime, ":" ) );
		defaultMinutes = val( listRest( defaultTime, ":" ) );
	}

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
		<input name="#inputName#" placeholder="#placeholder#" class="form-control timepicker" id="#inputId#" type="text" value="#HtmlEditFormat( value )#" autocomplete="off" tabindex="#getNextTabIndex()#" data-default-hour="#defaultHour#" data-default-minutes="#defaultMinutes#" />
		<i class="fa fa-clock-o"></i>
	</span>
</cfoutput>