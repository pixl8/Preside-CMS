/**
 * Handler for rules engine 'number type'
 *
 */
component {
	property name="formBuilderService"   inject="formBuilderService";

	private string function renderConfiguredField( string value="", struct config={} ) {

		if ( len( trim( arguments.config.question?:"" ) ) ) {
			var theQuestion  = formBuilderService.getQuestion( arguments.config.question );
			var questionConfig = DeserializeJson( theQuestion.item_type_config );
			switch ( questionConfig.format?:"" ) {
				case "free"  : return value ;
				case "price" : return decimalFormat( value );
			}
		}

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