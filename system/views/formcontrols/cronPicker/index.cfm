<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

	options         = args.options ?: [];
	fieldKeys       = [ "second", "minute", "hour", "dayofmonth", "monthofyear", "dayofweek" ];
	args.fieldValue = {};

	if ( !isEmpty( value ) ) {
		savedFieldValue = listToArray( value, " " );

		for ( var i=1; i<=arrayLen( savedFieldValue ); i++ ) {
			args.fieldValue[ fieldKeys[i] ] = savedFieldValue[i];
		}
	}
</cfscript>

<cfoutput>
	<input type="hidden" class="cron-picker #inputClass#" id="#inputId#" name="#inputName#" value="#HtmlEditFormat( value )#">

	<cfloop array="#options#" item="option">
		#renderFormControl(
			  name                    = option.field
			, type                    = "cronPickerItem"
			, context                 = args.context ?: "admin"
			, label                   = translateResource( uri="export.scheduledReport:formcontrol.#option.field#.label" )
			, includeCustomInputField = option.includeCustomInputField ?: false
			, fieldValue              = args.fieldValue
		)#
	</cfloop>

	<p><i>Schedule: <b><span class="cron-readable-config"></span></b></i></p>
</cfoutput>