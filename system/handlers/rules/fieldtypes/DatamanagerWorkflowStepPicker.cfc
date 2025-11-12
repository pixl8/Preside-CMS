/**
 * @feature datamanagerworkflow
 */
component {

	property name="datamanagerWorkflowService" inject="datamanagerWorkflowService";

	private string function renderConfiguredField( string value="", struct config={} ) {
		return _renderStep(
			  requiresFlowPrefix = ArrayLen( datamanagerWorkflowService.getAllWorkflows( objectName=arguments.config.objectName ?: "" ) ) > 1
			, flow               = ListDeleteAt( arguments.value, ListLen( arguments.value, "/" ), "/" )
			, step               = ListLast( arguments.value, "/" )
		);
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		var labels = [];
		var values = [];
		var flows  = datamanagerWorkflowService.getAllWorkflows( objectName=arguments.config.objectName ?: "" );

		for( var flow in flows ) {
			var steps = datamanagerWorkflowService.getAllStepsForWorkflow( flow );

			for( var step in steps ) {
				ArrayAppend( values, "#flow#/#step#" );
				ArrayAppend( labels, _renderStep(
					  requiresFlowPrefix = ArrayLen( flows ) > 1
					, flow               = flow
					, step               = step
				) );
			}
		}

		if ( ArrayLen( values ) ) {
			return renderFormControl(
				  name         = "value"
				, type         = "select"
				, label        = translateResource( "rules.dynamicWorkflowRules:step.picker.field.title" )
				, required     = true
				, ajax         = false
				, labels       = labels
				, values       = values
				, savedValue   = arguments.value
				, defaultValue = arguments.value
			);
		}

		return translateResource( "rules.dynamicWorkflowRules:step.picker.no.steps" );
	}

// HELPERS
	private string function _renderStep( requiresFlowPrefix, flow, step ) {
		var i18nBase = "datamanagerWorkflow.#flow#:";
		var prefix   = arguments.requiresFlowPrefix ? ( translateResource( uri=i18nBase & "title", defaultValue=arguments.flow ) & ": " ) : "";

		return prefix & translateResource( uri=i18nBase & "step.#arguments.step#.title", defaultValue=arguments.step );
	}


}