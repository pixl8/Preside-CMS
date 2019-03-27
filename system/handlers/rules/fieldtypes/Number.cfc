/**
 * Handler for rules engine 'number type'
 *
 */
component {

	private string function renderConfiguredField( string value="", struct config={} ) {
		return NumberFormat( value );
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		rc.delete( "value" );

		return renderFormControl(
			  name         = "value"
			, type         = "spinner"
			, label        = translateResource( config.fieldLabel ?: "cms:rulesEngine.fieldtype.number.config.label" )
			, savedValue   = arguments.value
			, defaultValue = arguments.value
			, required     = true
		);
	}

}