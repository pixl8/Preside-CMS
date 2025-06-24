/**
 * Handler for rules engine to retrieve a star rating field
 *
 * @feature rulesEngine and formbuilder
 */
component {

	property name="formBuilderService"   inject="formBuilderService";

	private string function renderConfiguredField( string value="", struct config={} ) {
		return arguments.value;
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		StructDelete( rc, "value" );

		var questionId  = arguments.config.question ?: ( rc.question ?: "" );
		var theQuestion = formBuilderService.getQuestion( questionId );

		if ( Len( theQuestion ) ) {
			var questionConfig = DeserializeJson( theQuestion.item_type_config );
			var inc            = isTrue( questionConfig.allowHalfStars ?: "" ) ? 0.5 : 1;

			var values = [];
			for ( var i=0; i<=questionConfig.starCount; i=i+inc ) {
				ArrayAppend( values, i );
			}

			return renderFormControl(
				  argumentCollection = arguments.config
				, name               = "value"
				, type               = "select"
				, label              = translateResource( config.fieldLabel ?: "cms:rulesEngine.fieldtype.starrating.config.label" )
				, context            = "formbuilder"
				, layout             = ""
				, savedValue         = arguments.value
				, defaultValue       = arguments.value
				, values             = values
				, minValue           = "0"
				, maxValue           = "5"
				, step               = "0.5"
				, required           = true
				, layout             = "formcontrols.layouts.field"
			);
		}

		return '<p class="alert alert-warning"><i class="fa fa-fw fa-exclamation-triangle"></i> #translateResource( "cms:rulesEngine.fieldtype.formbuilderQuestionStarRatingValue.no.choices.warning" )#</p>'
	}

}