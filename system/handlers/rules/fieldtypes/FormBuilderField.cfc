/**
 * Handler for rules engine 'form builder field type'
 *
 */
component {

	property name="formBuilderService" inject="formBuilderService";

	private string function renderConfiguredField( string value="", struct config={} ) {
		var id = Trim( arguments.value );

		if ( !id.len() ) {
			return config.defaultLabel ?: "";
		}

		var item = formBuilderService.getFormItem( id );

		return item.configuration.label ?: "Not found";
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		var formId = config.fbform ?: ( rc.fbform ?: ( rc.formid ?: "" ) );

		rc.delete( "value" );

		return renderFormControl(
			  argumentCollection = arguments.config
			, name               = "value"
			, type               = "formbuilderFieldPicker"
			, formId             = formId
			, label              = translateResource( "cms:rulesEngine.fieldtype.formbuilderFormField.config.label" )
			, savedValue         = arguments.value
			, defaultValue       = arguments.value
			, required           = true
		);
	}

}