component {

	property name="formBuilderService"  inject="FormBuilderService";
	property name="assetManagerService" inject="AssetManagerService";

	private string function renderConfiguredField( string value="", struct config={} ) {
		try {
			var formItemId = arguments.config.formbuilderItem ?: "";

			StructAppend( arguments.config, _getFieldConfig( formItemId=formItemId ) );

			if ( !isEmptyString( arguments.config.fieldType ?: ""  ) ) {
				return runEvent(
					  event          = "rules.fieldtypes.#arguments.config.fieldType#.renderConfiguredField"
					, prePostExempt  = true
					, private        = true
					, eventArguments = arguments
				);
			} else {
				if ( IsJSON( arguments.value ) ) {
					var data = DeserializeJSON( arguments.value );

					if ( !isEmptyString( data.dataType ?: "" ) && !isEmptyString( data.operator ?: "" ) ) {
						var propertyLabel = ( !isEmptyString( data.property ?: "" ) ? "#data.property# " : "" );
						var valueLabel    = "";

						if ( StructKeyExists( data, "value" ) ) {
							var dataValues = ListToArray( data.value );
							var dataLabels = [];

							if ( isEmptyString( arguments.config.object ?: "" ) ) {
								for ( var dataValue in dataValues ) {
									var index = ArrayFindNoCase( arguments.config.values ?: [], dataValue );

									ArrayAppend( dataLabels, arguments.config.labels[ index ] ?: dataValue );
								}
							} else {
								for ( var dataValue in dataValues ) {
									ArrayAppend( dataLabels, renderLabel( objectName=arguments.config.object, recordId=dataValue ) );
								}
							}

							valueLabel = " '#ArrayToList( dataLabels, ", " )#'";
						}

						return propertyLabel & translateResource( uri="formcontrols.dataComparisonPicker:operator.#data.dataType#.#data.operator#" ) & valueLabel;
					} else {
						return translateResource( uri="rules.fieldTypes.formbuilderPageAnswer:text" )
					}
				}

				return arguments.value;
			}
		} catch ( any e ) {
			logError( e );

			return "";
		}
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		var formItemId = arguments.config.formbuilderItem ?: "";

		StructAppend( arguments.config, _getFieldConfig( formItemId=formItemId ) );

		if ( !isEmptyString( arguments.config.fieldType ?: ""  ) ) {
			return runEvent(
				  event          = "rules.fieldtypes.#arguments.config.fieldType#.renderConfigScreen"
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
		var config = { label="", type="", fieldType="" };

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
						config.fieldType  = "timeperiod";
						config.fieldLabel = config.label;
						config.dataType   = "date";
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
							config.type   = "objectPicker";
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

					case "fileupload":
						config.multiple = true;
						config.dataType = "array";
						config.type     = "fileTypePicker";
						break;

					case "checkbox":
						config.type     = "";
						config.dataType = "boolean";
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