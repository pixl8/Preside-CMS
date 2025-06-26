/**
 * @feature        datamanagerWorkflow
 * @presideService true
 * @singleton      true
 */
component {

	property name="cfflow"                          inject="cfflow@cfflow";
	property name="cfflowFactory"                   inject="workflowFactory@cfflow";
	property name="specLibrary"                     inject="datamanagerWorkflowSpecLibrary";
	property name="specConverter"                   inject="datamanagerWorkflowToCfflowConverter";
	property name="datamanagerCustomizationService" inject="datamanagerCustomizationService";
	property name="specDirectories"                 inject="presidecms:directories:workflows/datamanager";
	property name="plantUmlService"                 inject="plantUmlDiagramService";

	public any function init() {
		return this;
	}

	public any function postInit() {
		_loadFlowsFromDisk();
	}

	public boolean function isWorkflowEnabled( required string objectName ) {
		if ( ReFindNoCase( "^vrsn_", arguments.objectName ) ) {
			return false;
		}

		return $helpers.isTrue( $getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "datamanagerWorkflowEnabled"
		) );
	}

	public string function getDefaultWorkflowId( required string objectName ) {
		return $getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "datamanagerWorkflowDefaultFlow"
			, defaultValue  = arguments.objectName
		);
	}

	public array function getAllWorkflows( required string objectName ) {
		var getFlowsHandler = "admin.datamanager.#arguments.objectName#.getAllWorkflows";

		if ( $getColdbox().handlerExists( getFlowsHandler ) ) {
			var result = $runEvent(
				  event          = getFlowsHandler
				, private        = true
				, prepostExempt  = true
			);

			return local.result ?: [];
		}

		return [ getDefaultWorkflowId( arguments.objectName ) ];
	}

	public array function getAllStepsForWorkflow( required string workflowId ) {
		var flow    = specLibrary.getWorkflow( arguments.workflowId );
		var stepIds = [];

		for( var step in flow.steps ) {
			ArrayAppend( stepIds, step.id );
		}

		return stepIds;
	}

	public array function getAllNonCompleteStepsForWorkflow( required string workflowId ) {
		var flow    = specLibrary.getWorkflow( arguments.workflowId );
		var stepIds = [];

		for( var step in flow.steps ) {
			if ( StructKeyExists( step, "actions" ) && ArrayLen( step.actions ) ) {
				ArrayAppend( stepIds, step.id );
			}
		}

		return stepIds;
	}

	public string function getWorkflowIdForRecord( required string objectName, required string recordId ) {
		var getFlowHandler = "admin.datamanager.#arguments.objectName#.getWorkflowForRecord";

		if ( $getColdbox().handlerExists( getFlowHandler ) ) {
			var result = $runEvent(
				  event          = getFlowHandler
				, private        = true
				, prepostExempt  = true
				, eventArguments = { recordId=arguments.recordId }
			);

			return local.result ?: "";
		}

		return getDefaultWorkflowId( arguments.objectName );
	}

	public string function getCfFlowWorkflowIdForRecord( required string objectName, required string recordId ) {
		return getCfflowWorkflowIdForFlow( getWorkflowIdForRecord( argumentCollection=arguments ) );
	}

	public string function getCfflowWorkflowIdForFlow( required string workflowId ) {
		return "datamanagerworkflow-" & arguments.workflowId;
	}


	public boolean function hasWorkflow(
		  required string objectName
		, required string recordId
	) {
		return isWorkflowEnabled( arguments.objectName ) && Len( getWorkflowIdForRecord( argumentCollection=arguments ) );
	}

	public any function createWorkflowForNewRecord( required string objectName, required string recordId ) {
		if ( !isWorkflowEnabled( arguments.objectName ) || !_objectCreatesWorkflowForNewRecords( arguments.objectName ) ) {
			return;
		}

		return getInstance( argumentCollection=arguments );
	}

	public void function deleteRelatedFlows( string objectName="" ) {
		if ( Len( arguments.objectName ) && !isWorkflowEnabled( arguments.objectName ) ) {
			return;
		}

		var idField = $getPresideObjectService().getIdField( arguments.objectName );
		if ( !Len( idField ) ) {
			return;
		}

		var subQueryFilters = [];
		ArrayAppend( subQueryFilters, { filter=$obfuscateSqlForPreside( "#arguments.objectName#.#idField# = cfflow_workflow_instance.sub_reference" ) } );
		if ( ArrayLen( arguments.extraFilters ?: [] ) ) {
			ArrayAppend( subQueryFilters, arguments.extraFilters, true );
		}

		var subQuery = $getPresideObjectService().selectData(
			  argumentCollection  = arguments
			, getSqlAndParamsOnly = true
			, formatSqlParams     = true
			, selectFields        = [ "1" ]
			, extraFilters        = extraFilters
		);

		var params = subQuery.params;
		params.reference = arguments.objectName;

		$getPresideObject( "cfflow_workflow_instance" ).deleteData(
			  filter       = "reference = :reference and exists (#$obfuscateSqlForPreside( subquery.sql )#)"
			, filterParams = subquery.params
		);
	}

	public WorkflowInstance function getInstance(
		  required string objectName
		, required string recordId
		,          string workflowId = getWorkflowIdForRecord( arguments.objectName, arguments.recordId )
	) {
		var cfflowName   = "datamanagerworkflow-" & arguments.workflowId;
		var args         = { reference=arguments.objectName, subReference=arguments.recordId };
		var instance     = cfflow.getInstance( workflowId=cfflowName, instanceArgs=args );

		return local.instance ?: cfflow.createInstance( workflowId=cfflowName, instanceArgs=args );
	}

	public array function getAvailableActions(
		  required string objectName
		, required string recordId
		,          string workflowId = getWorkflowIdForRecord( arguments.objectName, arguments.recordId )
	) {
		var wfInstance = Len( arguments.workflowId ) ? getInstance( argumentCollection=arguments ) : NullValue();

		if ( IsNull( local.wfInstance ) ) {
			return [];
		}

		var actions = [];
		for( var step in wfInstance.getActiveSteps() ) {
			ArrayAppend( actions, _getAvailableActionsForStep( workflowId=arguments.workflowId, stepId=step, wfInstance=wfInstance ), true );
		}

		return actions;
	}
	public boolean function hasActionPermission(
		  required string objectName
		, required string recordId
		, required string step
		, required string action
		,          string workflowId = getWorkflowIdForRecord( arguments.objectName, arguments.recordId )
		,          any    wfInstance = getInstance( arguments.objectName, arguments.recordId )
	) {
		var action = specLibrary.getWorkflowStepAction( arguments.workflowId, arguments.step, arguments.action );

		if ( StructCount( action.permission ?: {} ) ) {
			return _hasActionPermission( arguments.workflowId, arguments.step, arguments.action, action.permission, arguments.wfInstance );
		}

		return true;
	}

	public boolean function actionPassesCondition(
		  required string objectName
		, required string recordId
		, required string step
		, required string action
		,          string workflowId = getWorkflowIdForRecord( arguments.objectName, arguments.recordId )
		,          any    wfInstance = getInstance( arguments.objectName, arguments.recordId )
	) {
		var action = specLibrary.getWorkflowStepAction( arguments.workflowId, arguments.step, arguments.action );

		if ( StructCount( action.condition ?: {} ) ) {
			return cfflow.getWorkflowEngine().evaluateCondition(
				  wfInstance  = arguments.wfInstance
				, wfCondition = cfflowFactory.getCondition( argumentCollection=action.condition )
			);
		}
		return true;
	}

	public string function getFormNameForAction(
		  required string objectName
		, required string recordId
		, required string step
		, required string action
		,          string workflowId = getWorkflowIdForRecord( arguments.objectName, arguments.recordId )
	) {
		var action = specLibrary.getWorkflowStepAction( arguments.workflowId, arguments.step, arguments.action );

		return action.form ?: "";
	}

	public boolean function triggerAction(
		  required string objectName
		, required string recordId
		, required string step
		, required string action
		,          string workflowId = getWorkflowIdForRecord( arguments.objectName, arguments.recordId )
		,          struct formData = {}
	) {
		var wfInstance = getInstance( argumentCollection=arguments )
		var available  = _getAvailableActionsForStep( arguments.workflowId, arguments.step, wfInstance );

		if ( StructCount( arguments.formData ) ) {
			wfInstance.appendState( arguments.formData );
		}

		for( var action in available ) {
			if ( action.action == arguments.action ) {
				for( var wfStep in wfInstance.getWorkflowDefinition().getSteps() ) {
					if ( wfStep.getId() == arguments.step ) {
						for( var wfAction in wfStep.getActions() ) {
							if ( wfAction.getId() == arguments.action ) {
								cfflow.getWorkflowEngine().doAction( wfInstance=wfInstance, wfStep=wfStep, wfAction=wfAction );
								return true;
							}
						}
					}
				}
			}
		}

		return false;
	}

	public string function getStepStatus(
		  required string objectName
		, required string recordId
		, required string stepId
		,          any    wfInstance = getInstance( arguments.objectName, arguments.recordId )
	) {
		return arguments.wfInstance.getStepStatus( arguments.stepId );
	}

	public boolean function isStepActive(
		  required string objectName
		, required string recordId
		, required string stepId
		,          any    wfInstance = getInstance( arguments.objectName, arguments.recordId )
	) {
		return getStepStatus( argumentCollection=arguments ) == "active";
	}

	public boolean function isStepPending(
		  required string objectName
		, required string recordId
		, required string stepId
		,          any    wfInstance = getInstance( arguments.objectName, arguments.recordId )
	) {
		return getStepStatus( argumentCollection=arguments ) == "pending";
	}

	public boolean function isStepComplete(
		  required string objectName
		, required string recordId
		, required string stepId
		,          any    wfInstance = getInstance( arguments.objectName, arguments.recordId )
	) {
		return getStepStatus( argumentCollection=arguments ) == "complete";
	}

	public boolean function isStepSkipped(
		  required string objectName
		, required string recordId
		, required string stepId
		,          any    wfInstance = getInstance( arguments.objectName, arguments.recordId )
	) {
		return getStepStatus( argumentCollection=arguments ) == "skipped";
	}

	public boolean function isStepCompletedOrSkipped(
		  required string objectName
		, required string recordId
		, required string stepId
		,          any    wfInstance = getInstance( arguments.objectName, arguments.recordId )
	) {
		var status = getStepStatus( argumentCollection=arguments );

		return status == "complete" || status == "skipped";
	}

	public array function getActiveSteps(
		  required string objectName
		, required string recordId
		,          any    wfInstance = getInstance( arguments.objectName, arguments.recordId )
	) {
		return arguments.wfInstance.getActiveSteps();
	}

	public array function getStepStatuses(
		  required string objectName
		, required string recordId
		,          any    wfInstance = getInstance( arguments.objectName, arguments.recordId )
	) {
		return arguments.wfInstance.getAllStepStatuses();
	}

	public string function renderStatus(
		  required string objectName
		, required string recordId
		,          string workflowId = getWorkflowIdForRecord( arguments.objectName, arguments.recordId )
	) {
		var args = StructCopy( arguments );

		args.activeSteps = getActiveSteps( argumentCollection=arguments );

		return datamanagerCustomizationService.runCustomization(
			  objectName     = arguments.objectName
			, action         = "renderWorkflowStatus"
			, args           = args
			, defaultHandler = "admin.datamanagerWorkflow.renderWorkflowStatus"
			, defaultResult  = ArrayToList( args.activeSteps, ", " )
		);

	}

	public array function getTransitionHistory(
		  required string objectName
		, required string recordId
	) {
		var history       = [];
		var selectFields  = [ "id", "datecreated", "step", "action", "result", "triggered_by_admin_user" ];

		if ( $isFeatureEnabled( "websiteusers" ) ) {
			ArrayAppend( selectFields, "triggered_by_website_user" );
		}

		var actionHistory = $getPresideObject( "cfflow_workflow_instance_history" ).selectData(
			  selectFields = selectFields
			, orderby      = "datecreated desc"
			, filter       = {
				  "instance.workflow_id"   = getCfFlowWorkflowIdForRecord( argumentCollection=arguments )
				, "instance.reference"     = arguments.objectName
				, "instance.sub_reference" = arguments.recordId
			}
		);
		var transitionHistory = $getPresideObject( "cfflow_workflow_instance_history_transition" ).selectData(
			  selectFields = [ "step", "status", "old_status", "history" ]
			, orderby      = "history,datecreated"
			, filter       = {
				  "history$instance.workflow_id"   = getCfFlowWorkflowIdForRecord( argumentCollection=arguments )
				, "history$instance.reference"     = arguments.objectName
				, "history$instance.sub_reference" = arguments.recordId
			  }
		);

		for( var ah in actionHistory ) {
			ah.transitions = [];
			for( var th in transitionHistory ) {
				if ( th.history == ah.id ) {
					ArrayAppend( ah.transitions, th );
				} else if ( ArrayLen( ah.transitions ) ) {
					break;
				}
			}

			ArrayAppend( history, ah );
		}

		return history;
	}

	public string function renderFlowDiagram(
		  required string objectName
		, required string recordId
		,          string workflowId     = getWorkflowIdForRecord( arguments.objectName, arguments.recordId )
		,          any    wfInstance     = getInstance( arguments.objectName, arguments.recordId )
		,          string plantUmlStyles = _getDefaultPlantUmlStyles()
	) {
		return plantUmlService.umlToSvgDiagram( flowToPlantUml( argumentCollection=arguments ) );
	}

	public string function flowToPlantUml(
		  required string objectName
		, required string recordId
		,          string workflowId     = getWorkflowIdForRecord( arguments.objectName, arguments.recordId )
		,          any    wfInstance     = getInstance( arguments.objectName, arguments.recordId )
		,          string plantUmlStyles = _getDefaultPlantUmlStyles()
	) {
		var nl                = Chr( 10 );
		var plantUml          = "@startuml" & nl;

		if ( Len( Trim( arguments.plantUmlStyles ) ) ) {
			plantUml &= arguments.plantUmlStyles & nl;
		}

		if ( Len( arguments.workflowId ) && !IsNull( arguments.wfInstance ) ) {
			var steps = arguments.wfInstance.getAllStepStatuses();
			for( var step in steps ) {
				var i18nBase        = "datamanagerWorkflow.#arguments.workflowId#:step.#step.step#";
				var stepTitle       = $translateResource( uri="#i18nBase#.title", defaultValue=step.step );
				var stepDescription = $translateResource( uri="#i18nBase#.description", defaultValue="" );

				plantUml &= 'state "#stepTitle#" as #step.step#<<#LCase( step.status )#>>';
				if ( Len( stepDescription )  ) {
					plantUml &= ": #stepDescription#";
				}
					plantUml &= nl;
			}
			var stepTransitionReport = getStepTransitionReport( argumentCollection=arguments );

			for( var step in stepTransitionReport.initialSteps ) {
				plantUml &= "[*] --> #step#" & nl;
			}
			for( var fromStep in stepTransitionReport.stepTransitions ) {
				for( var toStep in stepTransitionReport.stepTransitions[ fromStep ] ) {
					plantUml &= "#fromStep# --> #toStep#" & nl;
				}
			}

			for( var step in stepTransitionReport.terminalSteps ) {
				plantUml &= "#step# --> [*]" & nl;
			}
		}

		plantUml &= nl & "@enduml";

		return plantUml;
	}

	public struct function getStepTransitionReport(
		  required string objectName
		, required string recordId
		,          string workflowId     = getWorkflowIdForRecord( arguments.objectName, arguments.recordId )
	) {
		var report = {
			  initialSteps    = []
			, stepTransitions = {}
			, terminalSteps   = {}
		};
		var definition = specLibrary.getWorkflow( arguments.workflowId );

		if ( StructCount( definition ) ) {
			for( var action in definition.initialActions ) {
				report.initialSteps = _getActiveStepTransitionsFromResults( action, definition );
			}

			for( var step in definition.steps ) {
				if ( !ArrayLen( step.actions ?: [] ) ) {
					report.terminalSteps[ step.id ] = true;
					continue;
				}
				report.stepTransitions[ step.id ] = {};
				for( var action in step.actions ) {
					for( var stepId in _getActiveStepTransitionsFromResults( action, definition ) ) {
						report.stepTransitions[ step.id ][ stepId ] = true;
					}
				}
			}
		}

		report.terminalSteps = StructKeyArray( report.terminalSteps );
		for( var fromStep in report.stepTransitions ) {
			report.stepTransitions[ fromStep ] = StructKeyArray( report.stepTransitions[ fromStep ] );
		}

		return report;
	}

// PRIVATE HELPERS
	private function _loadFlowsFromDisk() {
		var registeredFlows = [];
		for( var dir in specDirectories ) {
			if ( !DirectoryExists( ExpandPath( dir ) ) ) {
				continue;
			}

			var yamlFiles = DirectoryList( ExpandPath( dir ), false, "path", "*.yml" );

			ArraySort( yamlFiles, "textnocase" );

			for( var yamlFile in yamlFiles ) {
				var workflow = specLibrary.registerWorkflow( yamlFile );

				if ( !IsNull( workflow ) ) {
					cfflow.registerWorkflow( specConverter.convert( workflow ) );
					ArrayAppend( registeredFlows, workflow.id );
				}
			}

		}
	}

	private function _getAvailableActionsForStep( workflowId, stepId, wfInstance ) {
		var step             = specLibrary.getWorkflowStep( arguments.workflowId, arguments.stepId );
		var availableActions = [];
		var actions          = step.actions ?: [];

		for( var action in actions ) {
			if ( $helpers.isTrue( action.auto ?: "" ) ) {
				continue;
			}

			var availableAction = {
				  step            = arguments.stepId
				, action          = action.id
				, hasPermission   = true
				, passesCondition = true
			};

			if ( StructCount( action.condition ?: {} ) ) {
				availableAction.passesCondition = cfflow.getWorkflowEngine().evaluateCondition(
					  wfInstance  = arguments.wfInstance
					, wfCondition = cfflowFactory.getCondition( argumentCollection=action.condition )
				);
			}
			if ( StructCount( action.permission ?: {} ) ) {
				availableAction.hasPermission = _hasActionPermission(
					  workflowId = arguments.workflowId
					, stepId     = arguments.stepId
					, actionId   = action.id
					, permission = action.permission
					, wfInstance = arguments.wfInstance
				);
			}

			availableAction.enabled = availableAction.hasPermission && availableAction.passesCondition;

			ArrayAppend( availableActions, availableAction );
		}

		return availableActions;
	}

	private function _hasActionPermission( workflowId, stepId, actionId, permission, wfInstance ) {
		var hasPermission = true;

		if ( Len( arguments.permission.key ?: "" ) ) {
			hasPermission = $hasAdminPermission( arguments.permission.key );
		}

		if ( hasPermission && StructCount( arguments.permission.handler ?: {} ) ) {
			hasPermission = $helpers.isTrue( $runEvent(
				  event          = arguments.permission.handler.event
				, private        = true
				, prepostExempt  = true
				, eventArguments = {
					  args       = cfflow.getWorkflowEngine().substituteArgs( args=arguments.permission.handler.args ?: {}, wfInstance=wfInstance )
					, wfInstance = arguments.wfInstance
					, workflowId = arguments.workflowId
					, stepId     = arguments.stepId
					, actionId   = arguments.actionId
				  }
			) );
		}

		return hasPermission;
	}

	private function _objectCreatesWorkflowForNewRecords( objectName ) {
		return $helpers.isFalse( $getPresideObjectService().getObjectAttribute( arguments.objectName, "datamanagerWorkflowManualTrigger" ) );
	}

	private array function _getActiveStepTransitionsFromResults( results, definition ) {
		var steps = _getActiveStepTransitionsFromResult( arguments.results.result, arguments.definition );
		for( var result in arguments.results.conditionalResults ?: [] ) {
			StructAppend( steps, _getActiveStepTransitionsFromResult( result, arguments.definition ) );
		}

		return StructKeyArray( steps );
	}

	private struct function _getActiveStepTransitionsFromResult( result, definition ) {
		var steps = {};

		for( var step in arguments.result.activateSteps ?: [] ) {
			steps[ step ] = true;
		}
		for( var joinId in arguments.result.joins ?: [] ) {
			for( var join in arguments.definition.joins ?: [] ) {
				if ( join.id == joinId ) {
					for( var step in  _getActiveStepTransitionsFromResults( join, definition ) ) {
						steps[ step ] = true;
					}
				}
			}
		}

		return steps;
	}

	private function _getDefaultPlantUmlStyles() {
		return 'skinparam Padding 2
skinparam state {
  StartColor ##2b7dbc
  EndColor ##2b7dbc
  ArrowColor ##b2b6bf
  BorderColor ##2c3d4e
  BackgroundColor ##f5f5f5
  BackgroundColor<<active>> ##dff0d8
  BackgroundColor<<pending>> ##ffffff
  BackgroundColor<<complete>> ##f5f5f5
  BackgroundColor<<skipped>> ##ffffff
  BorderColor<<skipped>> ##cccccc
  FontColor<<skipped>> ##cccccc
  AttributeFontColor<<skipped>> ##cccccc
  BackgroundColor<<pending>> ##ffffff
  BorderColor<<pending>> ##cccccc
  FontColor<<pending>> ##cccccc
  AttributeFontColor<<pending>> ##cccccc
  FontSize 10
  AttributeFontSize 8
  AttributeFontStyle italic
}';
	}
}