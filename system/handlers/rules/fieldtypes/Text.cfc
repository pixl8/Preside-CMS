/**
 * Handler for rules engine 'text type'
 *
 */
component {

	private string function renderConfiguredField( string value="", struct config={} ) {
		return "&ldquo;" & value & "&rdquo;";
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		rc.delete( "value" );

		return renderFormControl(
			  name         = "value"
			, type         = "textinput"
			, label        = translateResource( "cms:rulesEngine.fieldtype.text.config.label" )
			, placeholder  = translateResource( config.placeholder ?: "cms:rulesEngine.fieldtype.text.config.placeholder" )
			, savedValue   = arguments.value
			, defaultValue = arguments.value
			, required     = true
		);
	}

}