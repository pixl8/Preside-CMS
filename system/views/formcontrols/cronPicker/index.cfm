<!---@feature presideForms--->
<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) ) {
		value = "";
	}

	options         = args.options ?: [];
	fieldKeys       = [ "second", "minute", "hour", "dayofmonth", "monthofyear", "dayofweek" ];
	args.fieldValue = {};

	if ( !isEmpty( value ) ) {
		savedFieldValue = listToArray( value, " " );

		for ( i=1; i<=arrayLen( savedFieldValue ); i++ ) {
			args.fieldValue[ fieldKeys[i] ] = savedFieldValue[i];
		}
	}

	htmlAttributes = renderHtmlAttributes(
		  attribs      = ( args.attribs      ?: {} )
		, attribNames  = ( args.attribNames  ?: "" )
		, attribValues = ( args.attribValues ?: "" )
		, attribPrefix = ( args.attribPrefix ?: "" )
	);
</cfscript>

<cfoutput>
	<input type="hidden" class="cron-picker #inputClass#" id="#inputId#" name="#inputName#" value="#HtmlEditFormat( value )#" #htmlAttributes# />

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
