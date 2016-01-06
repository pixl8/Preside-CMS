<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	placeholder  = args.placeholder  ?: "";
	defaultValue = args.defaultValue ?: "";

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

</cfscript>

<cfoutput>
	<span class="block input-icon input-icon-right">
		<input name="#inputName#" placeholder="#placeholder#" class="#inputClass# form-control icon-picker-fontawesome" id="#inputId#" type="text" value="#HtmlEditFormat( value )#" tabindex="#getNextTabIndex()#" data-placement="bottomLeft" />
		<i class="fa fa-crosshairs"></i>
	</span>
</cfoutput>