<cfscript>
	inputName        = args.name             ?: "";
	inputId          = args.id               ?: "";
	inputClass       = args.class            ?: "";
	placeholder      = args.placeholder      ?: "";
	defaultValue     = args.defaultValue     ?: "";
	minDate          = args.minDate          ?: "";
	maxDate          = args.maxDate          ?: "";
	relativeToField  = args.relativeToField  ?: "";
	relativeOperator = args.relativeOperator ?: "";
	defaultDate      = args.defaultDate      ?: "";
	language         = event.isAdminRequest() ? getModel( "i18n" ).getFWLanguageCode() : ListFirst( event.getLanguageCode(), "-" );

	defaultTime      = args.defaultTime  ?: "";

	defaultHour      = 0;
	defaultMinutes   = 0;
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
		value = DateTimeFormat( value, "yyyy-mm-dd HH:nn:ss" );
	}

	startDate = "";
	endDate   = "";
	if ( IsDate( minDate ) ) {
		startDate = dateFormat( minDate ,"yyyy-mm-dd" );
	}
	if ( IsDate( maxDate ) ) {
		endDate = dateFormat( maxDate ,"yyyy-mm-dd" );
	}

	if ( !IsDate( defaultDate ) ) {
		defaultDate = DateFormat( Now(), "yyyy-mm-dd" );
	}
</cfscript>

<cfoutput>
	<span class="block input-icon input-icon-right">
		<input name="#inputName#" placeholder="#placeholder#" class="#inputClass# form-control datetimepicker" id="#inputId#" type="text" value="#HtmlEditFormat( value )#" autocomplete="off" tabindex="#getNextTabIndex()#" data-language="#language#" data-default-date="#defaultDate#" data-default-hour="#defaultHour#" data-default-minutes="#defaultMinutes#" data-relative-to-field="#relativeToField#" data-relative-operator="#relativeOperator#" <cfif Len( Trim( startDate ) )> data-start-date="#startDate#"</cfif><cfif Len( Trim( endDate ) )> data-end-date="#endDate#"</cfif> />
		<i class="fa fa-calendar"></i>
	</span>
</cfoutput>