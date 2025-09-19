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
		, required string step
		, required string status
		,          boolean _is = true
	) {
		return getPresideObject( arguments.objectName ).dataExists(
			  id           = payload[ arguments.objectName ].id ?: ""
			, extraFilters = prepareFilters( argumentCollection=arguments )
		);
	}

	private array function prepareFilters(
		  required string  objectName
		, required string  step
		, required string  status
		,          boolean _is = true
	){
		if ( Len( arguments.step ) && Len( arguments.status ) ) {
			return filterService.prepareStepMatchesStatusFilter(
				  argumentCollection = arguments
				, workflow           = ListDeleteAt( arguments.step, ListLen( arguments.step, "/" ), "/" )
				, step               = ListLast( arguments.step, "/" )
			);
		}

		return [];
	}

	private string function getLabel( required string objectName ) {
		var defaultValue = translateResource( uri="rules.dynamicWorkflowRules:step.matches.status.label" );
		var uriRoot      = presideObjectService.getResourceBundleUriRoot( arguments.objectName );

		return translateResource(
			  uri          = uriRoot & "datamanager.workflow.filter.step.matches.status.label"
			, defaultValue = defaultValue
		);
	}

	private string function getText( required string objectName ) {
		var defaultValue = translateResource( uri="rules.dynamicWorkflowRules:step.matches.status.text" );
		var uriRoot      = presideObjectService.getResourceBundleUriRoot( arguments.objectName );

		return translateResource(
			  uri          = uriRoot & "datamanager.workflow.filter.step.matches.status.text"
			, defaultValue = defaultValue
		);
	}

}