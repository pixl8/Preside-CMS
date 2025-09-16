/**
 * @feature        datamanagerWorkflow
 * @presideService true
 * @singleton      true
 */
component {

	property name="datamanagerWorkflowService"   inject="datamanagerWorkflowService";
	property name="rulesEngineExpressionService" inject="rulesEngineExpressionService";

	public any function init() {
		return this;
	}

	public function registerDynamicFilterExpressions() {
		var objects = $getPresideObjectService().listObjects();

		for( var objectName in objects ) {
			if ( datamanagerWorkflowService.isWorkflowEnabled( objectName ) ) {
				registerDynamicFilterExpressionsForObject( objectName );
			}
		}
	}

	public function registerDynamicFilterExpressionsForObject( required string objectName ) {
		var handlerPrefix = "rules.dynamic.datamanagerWorkflowExpressions.";
		var idPrefix      = "presideobject_datamanagerworkflow_#arguments.objectName#_";
		var commonArgs    = {
			  filterObjects         = [ arguments.objectName ]
			, expressionHandlerArgs = { objectName=arguments.objectName }
			, filterHandlerArgs     = { objectName=arguments.objectName }
			, labelHandlerArgs      = { objectName=arguments.objectName }
			, textHandlerArgs       = { objectName=arguments.objectName }
			, category              = "datamanagerWorkflow"
		};

		rulesEngineExpressionService.addExpression(
			  argumentCollection    = commonArgs
			, id                    = idPrefix      & "stepstatus"
			, expressionHandler     = handlerPrefix & "stepMatchesStatus.evaluateExpression"
			, filterHandler         = handlerPrefix & "stepMatchesStatus.prepareFilters"
			, labelHandler          = handlerPrefix & "stepMatchesStatus.getLabel"
			, textHandler           = handlerPrefix & "stepMatchesStatus.getText"
			, fields                = {
				  step   = { fieldType="datamanagerWorkflowStepPicker", required=true, objectName=arguments.objectName, defaultLabel="rules.dynamicWorkflowRules:step.matches.status.field.step.default" }
				, status = { fieldType="enum", required=true, enum="cfflowStepStatus", multiple=false, defaultLabel="rules.dynamicWorkflowRules:step.matches.status.field.status.default" }
				, _is    = { fieldType="boolean", variety="isIsNot", default=true, required=false }
			  }
		);

		rulesEngineExpressionService.addExpression(
			  argumentCollection    = commonArgs
			, id                    = idPrefix      & "completed"
			, expressionHandler     = handlerPrefix & "flowIsCompleted.evaluateExpression"
			, filterHandler         = handlerPrefix & "flowIsCompleted.prepareFilters"
			, labelHandler          = handlerPrefix & "flowIsCompleted.getLabel"
			, textHandler           = handlerPrefix & "flowIsCompleted.getText"
			, fields                = {
				_is = { fieldType="boolean", variety="isIsNot", default=true, required=false }
			  }
		);
	}


	public function prepareStepMatchesStatusFilter(
		  required string  objectName
		, required string  workflow
		, required string  step
		, required string  status
		,          boolean _is = true
	) {
		/*
			Our target filter here looks like this:

			[not] exists (
				select 1
				from cfflow_workflow_instance cfflow_workflow_instance
				where reference = :objectname
				and workflow_id = :workflow
				and sub_reference = object_name.idfield
				and exists (
					select 1 from cfflow_workflow_instance_step
					where instance = cfflow_workflow_instance.id
					and step = :step
					and status = :status
				)
			);

			For pending steps checks, we also have to check that there
			is no step entry at all.
		*/


		var idField       = $getPresideObjectService().getIdField( arguments.objectName );
		var cfflowWfId    = datamanagerWorkflowService.getCfflowWorkflowIdForFlow( arguments.workflow );
		var mainOuterJoin = "cfflow_workflow_instance.sub_reference = #objectName#.#idField#";
		var stepOuterJoin = "instance = cfflow_workflow_instance.id"
		var paramPrefix   = _getParamPrefix();
		var stepSubQuery  = $getPresideObject( "cfflow_workflow_instance_step" ).selectData(
			  selectFields        = [ "1" ]
			, filter              = { step=arguments.step, status=arguments.status }
			, extraFilters        = [ { filter=$obfuscateSqlForPreside( stepOuterJoin ) } ]
			, getSqlAndParamsOnly = true
			, formatSqlParams     = true
			, sqlAndParamsPrefix  = paramPrefix
		);
		var params = StructCopy( stepSubQuery.params );

		var instanceFilters = [
			  { filter=$obfuscateSqlForPreside( mainOuterJoin ) }
		];

		if ( arguments.status == "pending" ) {
			var noStepSubQuery = $getPresideObject( "cfflow_workflow_instance_step" ).selectData(
				  selectFields        = [ "1" ]
				, filter              = { step=arguments.step }
				, extraFilters        = [ { filter=$obfuscateSqlForPreside( stepOuterJoin ) } ]
				, getSqlAndParamsOnly = true
				, formatSqlParams     = true
				, sqlAndParamsPrefix  = paramPrefix
			);
			StructAppend( params, noStepSubQuery.params );

			ArrayAppend( instanceFilters, {
				  filter       = $obfuscateSqlForPreside( "exists (#stepSubQuery.sql#) or not exists (#noStepSubQuery.sql#)" )
				, filterParams = params
			} );
		} else {
			ArrayAppend( instanceFilters, {
				  filter       = $obfuscateSqlForPreside( "exists (#stepSubQuery.sql#)" )
				, filterParams = params
			} );
		}

		var instanceSubQuery =  $getPresideObject( "cfflow_workflow_instance" ).selectData(
			  selectFields        = [ "1" ]
			, filter              = { reference=arguments.objectName, workflow_id=cfflowWfId }
			, extraFilters        = instanceFilters
			, getSqlAndParamsOnly = true
			, formatSqlParams     = true
			, sqlAndParamsPrefix  = paramPrefix
		);

		StructAppend( params, instanceSubQuery.params );

		var exists = arguments._is ? "exists" : "not exists";

		return [{
			  filter       = "#exists# (#$obfuscateSqlForPreside( instanceSubQuery.sql )#)"
			, filterParams = params
		}];
	}

	public function prepareFlowIsCompletedFilter(
		  required string  objectName
		,          boolean _is = true
	) {
		/*
			Our target filter here looks like this:

			not exists (
				select 1
				from cfflow_workflow_instance_step
				inner join cfflow_workflow_instance on cfflow_workflow_instance.id = cfflow_workflow_instance_step.instance
				where cfflow_workflow_instance.workflow_id = :flow_id
				and cfflow_workflow_instance.reference = :objectname
				and cfflow_workflow_instance.sub_reference = [objectName.idfield]
				and cfflow_workflow_instance_step.step in (:stepsthatAreNotEndSteps)
				and cfflow_workflow_instance_step.status = 'active'
			) and not exists( ... repeat for each flow for the object ... );
		*/

		var allFlows      = datamanagerWorkflowService.getAllWorkflows( arguments.objectName );
		var idField       = $getPresideObjectService().getIdField( arguments.objectName );
		var exists        = arguments._is ? "not exists" : "exists"; // yes, correct
		var subQueryDelim = exists;
		var outerJoin     = $obfuscateSqlForPreside( "instance.sub_reference = #objectName#.#idField#" );
		var filter        = "";
		var params        = {};

		for( var flow in datamanagerWorkflowService.getAllWorkflows( arguments.objectName ) ) {
			var nonCompleteSteps = datamanagerWorkflowService.getAllNonCompleteStepsForWorkflow( flow );
			var cfflowWfId       = datamanagerWorkflowService.getCfflowWorkflowIdForFlow( flow );
			var subQuery         = $getPresideObject( "cfflow_workflow_instance_step" ).selectData(
				  selectFields        = [ 1 ]
				, filter              = { step=nonCompleteSteps, status="active", "instance.workflow_id"=cfflowWfId, "instance.reference"=arguments.objectName }
				, extraFilters        = [ { filter=outerJoin }]
				, getSqlAndParamsOnly = true
				, formatSqlParams      = true
				, sqlAndParamsPrefix   = _getParamPrefix()
			);


			StructAppend( params, subQuery.params );
			filter &= subQueryDelim & " (#$obfuscateSqlForPreside( subQuery.sql )#)";

			subQueryDelim = arguments._is ? "and not exists" : "or exists";
		}

		return [{
			  filter       = filter
			, filterParams = params
		}];
	}

// HELPERS
	private function _getParamPrefix() {
		return Replace( LCase( CreateUUId() ), "-", "", "all" );
	}

}