<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) ) {
		value = "";
	}

	value = EncodeForHTML( value );

	renderedOperatorFormControl = args.renderedOperatorFormControl ?: "";
	renderedValueFormControl    = args.renderedValueFormControl    ?: "";
	renderedPropertyFormControl = args.renderedPropertyFormControl ?: "";

	dataType = args.dataType ?: "";
</cfscript>

<cfoutput>
	<input type="hidden" id="#inputId#"          name="#inputName#"          value="#value#" class="#inputClass# form-control form-control-data-comparison-picker" />
	<input type="hidden" id="#inputId#_datatype" name="#inputName#_datatype" value="#dataType#" />

	#renderedPropertyFormControl#

	#renderedOperatorFormControl#

	#renderedValueFormControl#
</cfoutput>
