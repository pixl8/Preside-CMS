/**
 * Handler for rules engine to retrieve a star rating field
 */
component {
	property name="formBuilderService"   inject="formBuilderService";

	private string function renderConfiguredField( string value="", struct config={} ) {
		return NumberFormat( value );
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		rc.delete( "value" );
		var questionId = config.question ?: ( rc.question ?: "" );
		var theQuestion = formBuilderService.getQuestion( questionId );


		var questionConfig = DeserializeJson( theQuestion.item_type_config );

		var values = [];
		for (var i = 0; i<=questionConfig.starCount; i=i+0.5) {
			arrayAppend( values, i );
		}

		return renderFormControl(
			  argumentCollection = arguments.config
			, name               = "value"
			, type               = "select"
			, label              = translateResource( config.fieldLabel ?: "cms:rulesEngine.fieldtype.starrating.config.label" )
			, context            = "formbuilder"
			, layout             = ""
			, savedValue   = arguments.value
			, defaultValue = arguments.value
			, values       = values
			, minValue     = "0"
			, maxValue     = "5"
			, step         = "0.5"
			, required     = true
			, layout         = "formcontrols.layouts.field"
		);

	}

}