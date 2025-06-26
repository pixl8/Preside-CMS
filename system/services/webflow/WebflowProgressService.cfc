/**
 * @feature        webflow
 * @presideService true
 * @singleton      true
 */
component {

	variables._localCache = {};

// CONSTRUCTOR
	/**
	 * @cfflow.inject cfflow@cfflow
	 * @webflowConfigurationService.inject webflowConfigurationService
	 *
	 */
	public any function init(
		  required any cfflow
		, required any webflowConfigurationService
	) {
		_setWorkflowEngine( arguments.cfflow.getWorkflowEngine() );
		_setWebflowConfigurationService( arguments.webflowConfigurationService );

		return this;
	}

// PUBLIC API METHODS
	public array function getProgressIndicators( required WorkflowInstance instance ) {
		var stepStatuses = arguments.instance.getAllStepStatuses();
		var progress     = [];

		for( var step in stepStatuses ) {
			if ( step.status == "active" || step.status == "complete" ) {
				if ( _reportStepProgress( step.step, instance ) ) {
					progress.append( step );
				}
				if ( step.status == "active" ) {
					break;
				}
			}
		}

		var nextStep = _getStep( arguments.instance, arguments.instance.getActiveStep() );
		do {
			nextStep = _getNextStep( instance, nextStep );
			if ( !IsNull( local.nextStep ) && _reportStepProgress( nextStep.getId(), instance ) ) {
				progress.append( { step=nextStep.getId(), status="pending" } );
			}
		} while( !IsNull( local.nextStep ) );

		return progress;
	}

// PRIVATE HELPERS
	private WorkflowStep function _getStep( instance, stepId ) {
		for( var step in arguments.instance.getWorkflowDefinition().getSteps() ) {
			if ( step.getId() == stepId ) {
				return step;
			}
		}
	}

	private any function _getNextStep( instance, step ) {
		var nextAction = _getNextAction( arguments.step );

		if ( IsNull( local.nextAction ) ) {
			return;
		}

		var result = _getWorkflowEngine().getResultToExecute( arguments.instance, nextAction );

		if ( IsNull( local.result ) ) {
			return;
		}

		for( var transition in result.getTransitions() ) {
			if ( transition.getStatus() == "active" ) {
				return _getStep( arguments.instance, transition.getStep() );
			}
		}
	}

	private any function _getNextAction( step ) {
		var actions = step.getActions();
		for( var action in actions ) {
			if ( action.getId() == "next" ) {
				return action;
			}
		}
	}

	private boolean function _reportStepProgress( required string stepId, required WorkflowInstance instance ) {
		var instanceArgs = instance.getInstanceArgs();
		var webflowId    = instanceArgs.reference    ?: "";
		var instanceRef  = instanceArgs.subreference ?: "";
		var cacheKey     = "_reportStepProgress" & arguments.stepId & webflowId & instanceRef;

		return _simpleLocalCache( cacheKey, function(){
			var stepConfig = _getWebflowConfigurationService().getStepConfig(
				  webflowId   = webflowId
				, stepId      = stepId
				, instanceRef = instanceRef
			);
			return !IsBoolean( stepConfig.hideProgress ?: "" ) || !stepConfig.hideProgress;
		} );
	}

	private any function _simpleLocalCache( required string cacheKey, required any processor ){
		if ( !StructKeyExists( variables._localCache, arguments.cacheKey ) ) {
			variables._localCache[ arguments.cacheKey ] = processor();
		}

		return variables._localCache[ arguments.cacheKey ];
	}

// GETTERS AND SETTERS
	private any function _getWorkflowEngine() {
		return _workflowEngine;
	}
	private void function _setWorkflowEngine( required any workflowEngine ) {
		_workflowEngine = arguments.workflowEngine;
	}

	private any function _getWebflowConfigurationService() {
		return _webflowConfigurationService;
	}
	private void function _setWebflowConfigurationService( required any webflowConfigurationService ) {
		_webflowConfigurationService = arguments.webflowConfigurationService;
	}
}