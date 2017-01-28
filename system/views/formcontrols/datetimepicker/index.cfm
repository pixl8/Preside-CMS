<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	placeholder  = args.placeholder  ?: "";
	defaultValue = args.defaultValue ?: "";
	language     = event.isAdminRequest() ? getPlugin( "i18n" ).getFWLanguageCode() : ListFirst( event.getLanguageCode(), "-" );

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

	if ( IsDate( value ) ) {
		value = DateTimeFormat( value, "yyyy-mm-dd HH:nn:ss" );
	}
</cfscript>

<cfoutput>
	<span class="block input-icon input-icon-right">
		<input name="#inputName#" placeholder="#placeholder#" class="#inputClass# form-control datetimepicker" id="#inputId#" type="text" value="#HtmlEditFormat( value )#" tabindex="#getNextTabIndex()#" data-language="#language#" />
		<i class="fa fa-calendar"></i>
	</span>
</cfoutput>