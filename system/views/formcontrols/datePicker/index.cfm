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
		value = DateFormat( value, "yyyy-mm-dd" );
	}
</cfscript>

<cfoutput>
	<span class="block input-icon input-icon-right">
		<input name="#inputName#" placeholder="#placeholder#" class="form-control date-picker" id="#inputId#" type="text" data-date-format="yyyy-mm-dd" value="#HtmlEditFormat( value )#" tabindex="#getNextTabIndex()#" />
		<i class="fa fa-calendar"></i>
	</span>
</cfoutput>