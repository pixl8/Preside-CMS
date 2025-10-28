/**
 * Handler for rules engine 'webflow step' type
 *
 * @feature rulesEngine and webflow
 */
component {

	property name="webflowLibrary" inject="WebflowSpecLibrary";

	private string function renderConfiguredField( string value="", struct config={} ) {
		var steps    = ListToArray( Trim( arguments.value ) );
		var rendered = [];

		for( var step in steps ) {
			ArrayAppend( rendered, _renderStepTitle( step ) );
		}

		if ( ArrayLen( rendered ) ) {
			return ArrayToList( rendered, ", " );
		}

		return arguments.config.defaultLabel ?: "";
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		var multiple  = IsTrue( arguments.config.multiple ?: false );
		var values    = [];
		var labels    = [];
		var webflowId = Trim( rc.webflow ?: "" );

		if ( Len( webflowId ) ) {
			var webflow = webflowLibrary.getWebflow( id=webflowId );

			for( var step in ( webflow?.getSteps() ?: [] ) ) {
				var stepId = step?.getId() ?: "";

				if ( Len( stepId ) ) {
					ArrayAppend( values, stepId );
					ArrayAppend( labels, _renderStepTitle( stepId ) );
				}
			}
		}

		rc.delete( "value" );

		return renderFormControl(
			  name               = "value"
			, type               = "select"
			, multiple           = multiple
			, values             = values
			, labels             = labels
			, label              = translateResource( "cms:rulesEngine.fieldtype.webflowStep.config.label" )
			, savedValue         = arguments.value
			, defaultValue       = arguments.value
			, includeEmptyOption = true
			, required           = isTrue( arguments.config.required ?: false )
		);
	}

// HELPERs
	private string function _renderStepTitle( required string stepId ) {
		return translateResource( uri="webflow.step.#arguments.stepId#:title", defaultValue=arguments.stepId ) & " (#stepId#)";
	}
}