/**
 * Dynamic expression handler for checking
 * whether or not the record's workflows
 * step is in a particular status
 *
 * @feature rulesEngine && datamanagerworkflow
 */
component {

	property name="filterService"        inject="datamanagerWorkflowFilterService";
	property name="presideObjectService" inject="presideObjectService";

	private boolean function evaluateExpression(
		  required string objectName
		,          boolean _is = true
	) {
		return getPresideObject( arguments.objectName ).dataExists(
			  id           = payload[ arguments.objectName ].id ?: ""
			, extraFilters = prepareFilters( argumentCollection=arguments )
		);
	}

	private array function prepareFilters(
		  required string  objectName
		,          boolean _is = true
	){
		return filterService.prepareFlowIsCompletedFilter( argumentCollection=arguments );
	}

	private string function getLabel( required string objectName ) {
		var defaultValue = translateResource( uri="rules.dynamicWorkflowRules:flow.is.completed.label" );
		var uriRoot      = presideObjectService.getResourceBundleUriRoot( arguments.objectName );

		return translateResource(
			  uri          = uriRoot & "datamanager.workflow.filter.flow.is.completed.label"
			, defaultValue = defaultValue
		);
	}

	private string function getText( required string objectName ) {
		var defaultValue = translateResource( uri="rules.dynamicWorkflowRules:flow.is.completed.text" );
		var uriRoot      = presideObjectService.getResourceBundleUriRoot( arguments.objectName );

		return translateResource(
			  uri          = uriRoot & "datamanager.workflow.filter.flow.is.completed.text"
			, defaultValue = defaultValue
		);
	}

}