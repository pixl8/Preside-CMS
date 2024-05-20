<!---@feature presideForms--->
<cfscript>
	inputName        = args.name             ?: "";
	inputId          = args.id               ?: "";
	placeholder      = args.placeholder      ?: "";
	defaultValue     = args.defaultValue     ?: "";
	defaultTime      = args.defaultTime      ?: "";
	minTime          = args.minTime 	     ?: "";
	maxTime          = args.maxTime 	     ?: "";
	relativeToField  = args.relativeToField  ?: "";
	relativeOperator = args.relativeOperator ?: "";
	timePickerClass  = args.timePickerClass  ?: "timepicker";

	defaultHour    = 0;
	defaultMinutes = 0;
	if ( defaultTime == "now" ) {
		defaultHour    = hour( now() );
		defaultMinutes = minute( now() );
	} else if ( len( defaultTime ) ) {
		defaultHour    = val( listFirst( defaultTime, ":" ) );
		defaultMinutes = val( listRest( defaultTime, ":" ) );
	}

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) ) {
		value = "";
	}

	if ( IsDate( value ) ) {
		value = datetimeFormat( value, "HH:nn" );
	}

	htmlAttributes = renderHtmlAttributes(
		  attribs      = ( args.attribs      ?: {} )
		, attribNames  = ( args.attribNames  ?: "" )
		, attribValues = ( args.attribValues ?: "" )
		, attribPrefix = ( args.attribPrefix ?: "" )
	);
</cfscript>

<cfoutput>
	<span class="block input-icon input-icon-right">
		<input name="#inputName#" placeholder="#placeholder#" class="form-control #timePickerClass#" id="#inputId#" type="text" data-relative-to-field="#relativeToField#" data-relative-operator="#relativeOperator#" data-time-format="" value="#HtmlEditFormat( value )#" autocomplete="off" tabindex="#getNextTabIndex()#" data-default-hour="#defaultHour#" data-default-minutes="#defaultMinutes#" #htmlAttributes# />
		<i class="fa fa-clock"></i>
	</span>
</cfoutput>
