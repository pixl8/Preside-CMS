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
	language         = event.isAdminRequest() ? getModel( "i18n" ).getFWLanguageCode() : ListFirst( event.getLanguageCode(), "-" );

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
</cfscript>

<cfoutput>
	<span class="block input-icon input-icon-right">
		<input name="#inputName#" placeholder="#placeholder#" class="#inputClass# form-control datetimepicker" id="#inputId#" type="text" value="#HtmlEditFormat( value )#" tabindex="#getNextTabIndex()#" data-language="#language#" data-relative-to-field="#relativeToField#" data-relative-operator="#relativeOperator#" <cfif Len( Trim( startDate ) )> data-start-date="#startDate#"</cfif><cfif Len( Trim( endDate ) )> data-end-date="#endDate#"</cfif> />
		<i class="fa fa-calendar"></i>
	</span>
</cfoutput>