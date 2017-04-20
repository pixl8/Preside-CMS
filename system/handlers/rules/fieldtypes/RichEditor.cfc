/**
 * Handler for rules engine 'richeditor type'
 *
 */
component {

	private string function renderConfiguredField( string value="", struct config={} ) {
		return arguments.value;
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		return renderFormControl(
			  name         = "value"
			, type         = "RichEditor"
			, label        = translateResource( config.fieldLabel ?: "cms:rulesEngine.fieldtype.richeditor.config.label" )
			, savedValue   = arguments.value
			, defaultValue = arguments.value
			, required     = true
		);
	}

}