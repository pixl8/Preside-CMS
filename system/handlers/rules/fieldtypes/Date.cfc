/**
 * Handler for rules engine 'date type'
 *
 */
component {

	private string function renderConfiguredField( string value="", struct config={} ) {
		if ( IsDate( arguments.value ) ) {
			return renderContent( renderer="date", data=arguments.value );
		}

		return translateResource( "cms:rulesEngine.fieldtype.date.defaultlabel" );
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		return renderFormControl(
			  name         = "value"
			, type         = "datePicker"
			, label        = translateResource( "cms:rulesEngine.fieldtype.date.config.label" )
			, savedValue   = arguments.value
			, defaultValue = arguments.value
			, required     = true
		);
	}


}