component {

	property name="formBuilderService" inject="FormBuilderService";

	private string function renderConfiguredField( string value="", struct config={} ) {
		var formItemId = arguments.config.formbuilderItem ?: "";

		StructAppend( arguments.config, _getFieldConfig( formItemId=formItemId ) );

		if ( ArrayContainsNoCase( [ "timeperiod" ], arguments.config.type ) ) {
			return runEvent(
				  event          = "rules.fieldtypes.#arguments.config.type#.renderConfiguredField"
				, prePostExempt  = true
				, private        = true
				, eventArguments = arguments
			);
		} else {
			if ( IsJSON( arguments.value ) ) {
				var data = DeserializeJSON( arguments.value );

				if ( !isEmptyString( data.dataType ?: "" ) && !isEmptyString( data.operator ?: "" ) ) {
					return ( !isEmptyString( data.property ?: "" ) ? "#data.property# " : "" ) & translateResource( uri="formcontrols.dataComparisonPicker:operator.#data.dataType#.#data.operator#" ) & " '#( data.value ?: "" )#'";
				} else {
					return translateResource( uri="rules.fieldTypes.formbuilderPageAnswer:text" )
				}
			}

			return arguments.value;
		}
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		var formItemId = arguments.config.formbuilderItem ?: "";

		StructAppend( arguments.config, _getFieldConfig( formItemId=formItemId ) );

		if ( ArrayContainsNoCase( [ "timeperiod" ], arguments.config.type ) ) {
			return runEvent(
				  event          = "rules.fieldtypes.#arguments.config.type#.renderConfigScreen"
				, prePostExempt  = true
				, private        = true
				, eventArguments = arguments
			);
		} else {
			return renderFormControl(
				  argumentCollection  = arguments.config
				, name                = "value"
				, type                = "DataComparisonPicker"
				, label               = arguments.config.label
				, savedValue          = arguments.value
				, defaultValue        = arguments.value
				, formControl         = arguments.config
			);
		}
	}

	private struct function _getFieldConfig( required string formItemId ) {
		var config = {};

		var formItem = formBuilderService.getFormItem( id=arguments.formItemId );

		if ( !StructIsEmpty( formItem ) ) {
			if ( formItem.type.isFormField ) {
				config.label = formItem.configuration.label ?: "";

				switch ( LCase( formItem.type.id ) ) {
					case "number":
					case "starrating":
						config.type     = "spinner";
						config.dataType = "numeric";
						break;

					case "date":
					case "time":
						config.type = "timeperiod";
						break;

					case "select":
					case "radio":
					case "checkboxlist":
						config.multiple = true;
						config.sortable = true;
						config.dataType = "array";

						if ( isEmptyString( formItem.configuration.datamanagerObject ?: "" ) ) {
							config.type   = "select";
							config.values = ListToArray( formItem.configuration.values ?: "", Chr( 10 ) & Chr( 13 ) );
							config.labels = ListToArray( formItem.configuration.labels ?: "", Chr( 10 ) & Chr( 13 ) );
						} else {
							config.type   = "object";
							config.object = formItem.configuration.datamanagerObject;
							config.ajax   = false;
						}
						break;

					case "matrix":
						config.multiple    = true;
						config.sortable    = true;
						config.dataType    = "array";
						config.type        = "select";
						config.values      = ListToArray( formItem.configuration.columns ?: "", Chr( 10 ) & Chr( 13 ) );
						config.formControl = {
							  type   = "select"
							, values = ListToArray( formItem.configuration.rows ?: "", Chr( 10 ) & Chr( 13 ) )
						};
						break;

					case "textinput":
					case "textarea":
					case "email":
					case "url":
					default:
						config.type = "textinput";
				}
			}
		}

		return config;
	}

}