/**
 * Handler for rules engine 'webflow' type
 *
 * @feature rulesEngine and webflow
 */
component {

	property name="webflowLibrary" inject="WebflowSpecLibrary";

	private string function renderConfiguredField( string value="", struct config={} ) {
		var webflows = ListToArray( Trim( arguments.value ) );
		var rendered = [];

		for( var webflow in webflows ) {
			ArrayAppend( rendered, _renderWebflowTitle( webflow ) );
		}

		if ( ArrayLen( rendered ) ) {
			return ArrayToList( rendered, ", " );
		}

		return arguments.config.defaultLabel ?: "";
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		var multiple = IsTrue( config.multiple ?: false );
		var values   = [];
		var labels   = [];

		for( var webflow in webflowLibrary.getAllWebflows() ) {
			ArrayAppend( values, webflow );
			ArrayAppend( labels, _renderWebflowTitle( webflow ) );
		}

		rc.delete( "value" );

		return renderFormControl(
			  name               = "value"
			, type               = "select"
			, multiple           = multiple
			, values             = values
			, labels             = labels
			, label              = translateResource( "cms:rulesEngine.fieldtype.webflow.config.label" )
			, savedValue         = arguments.value
			, defaultValue       = arguments.value
			, includeEmptyOption = true
			, required           = isTrue( arguments.config.required ?: true )
		);
	}

// HELPERs
	private string function _renderWebflowTitle( required string webflowId ) {
		return translateResource( uri="webflow.#arguments.webflowId#:title", defaultValue=arguments.webflowId );
	}
}