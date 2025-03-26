component {

	property name="formBuilderService" inject="FormBuilderService";

	private string function renderConfiguredField( string value="", struct config={} ) {
		var formItemId = arguments.config.formbuilderItem ?: "";

		StructAppend( arguments.config, _getFieldConfig( formItemId=formItemId ) );

		return runEvent(
			  event          = "rules.fieldtypes.#( arguments.config.fieldType ?: "text" )#.renderConfiguredField"
			, prePostExempt  = true
			, private        = true
			, eventArguments = arguments
		);
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		var formItemId = arguments.config.formbuilderItem ?: "";

		StructAppend( arguments.config, _getFieldConfig( formItemId=formItemId ) );

		return runEvent(
			  event          = "rules.fieldtypes.#( arguments.config.fieldType ?: "text" )#.renderConfigScreen"
			, prePostExempt  = true
			, private        = true
			, eventArguments = arguments
		);
	}

	private struct function _getFieldConfig( required string formItemId ) {
		var config = {};

		var formItem = formBuilderService.getFormItem( id=arguments.formItemId );

		if ( !StructIsEmpty( formItem ) ) {
			if ( formItem.type.isFormField ) {
				switch ( LCase( formItem.type.id ) ) {
					case "number":
						config.fieldType = "number";
						break;

					case "date":
					case "time":
						config.fieldType = "timeperiod";
						break;

					case "select":
					case "radio":
					case "checkboxlist":
						if ( isEmptyString( formItem.configuration.datamanagerObject ?: "" ) ) {
							config.fieldType = "select";
							config.values    = ListToArray( formItem.configuration.values ?: "", Chr( 10 ) & Chr( 13 ) );
							config.labels    = ListToArray( formItem.configuration.labels ?: "", Chr( 10 ) & Chr( 13 ) );
						} else {
							config.fieldType = "object";
							config.object    = formItem.configuration.datamanagerObject;
							config.ajax      = false;
						}
						break;

					case "textinput":
					case "textarea":
					case "email":
					case "url":
					default:
						config.fieldType = "text";
				}
			}
		}

		return config;
	}

}