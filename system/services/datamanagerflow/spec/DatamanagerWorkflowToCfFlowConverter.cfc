/**
 * @feature        datamanagerWorkflow
 * @presideService true
 * @singleton      true
 */
component {

	property name="cfflowFactory" inject="workflowFactory@cfflow";

	public function init() {
		return this;
	}

// PUBLIC API METHODS
	public Workflow function convert( required struct flow ) {
		var convertedFlow = cfflowFactory.getWorkflow(
			  id    = "datamanagerworkflow-" & arguments.flow.id
			, class = "preside.datamanagerflow.flow"
		);

		_convertInitialActions( convertedFlow, arguments.flow.initialActions );

		for( var step in arguments.flow.steps ) {
			_convertStep( convertedFlow, step );
		}

		for( var join in ( arguments.flow.joins ?: [] ) ) {
			_convertJoin( convertedFlow, join );
		}

		return convertedFlow;
	}

// PRIVATE HELPERS
	private function _convertInitialActions( convertedFlow, initialActions ) {
		for( var action in arguments.initialActions ) {
			_convertAction(
				  action       = action
				, cfflowAction = arguments.convertedFlow.addInitialAction( id=action.id, isAutomatic=true )
			);
		}
	}

	private function _convertResultTransitions( result, cfflowResult, stepId="" ) {
		if ( Len( arguments.stepId ) ) {
			arguments.cfflowResult.addTransition( step=arguments.stepId, status=( arguments.result.thisStep ?: "complete" ) );
		}
		if ( IsArray( arguments.result.activateSteps ?: "" ) ) {
			for( var stepId in arguments.result.activateSteps ) {
				arguments.cfflowResult.addTransition( stepId, "active" );
			}
		}
		if ( IsArray( arguments.result.skipSteps ?: "" ) ) {
			for( var stepId in arguments.result.skipSteps ) {
				arguments.cfflowResult.addTransition( stepId, "skipped" );
			}
		}
		if ( IsArray( arguments.result.completeSteps ?: "" ) ) {
			for( var stepId in arguments.result.completeSteps ) {
				arguments.cfflowResult.addTransition( stepId, "complete" );
			}
		}
		if ( IsArray( arguments.result.pendingSteps ?: "" ) ) {
			for( var stepId in arguments.result.pendingSteps ) {
				arguments.cfflowResult.addTransition( stepId, "pending" );
			}
		}
	}

	private function _convertResultFunctions( result, cfflowResult ) {
		var preHandlers  = arguments.result.preHandlers  ?: [];
		var postHandlers = arguments.result.postHandlers ?: [];

		for( var preHandler in preHandlers ) {
			if ( Len( Trim( preHandler.event ?: "" ) ) ) {
				arguments.cfflowResult.addPreFunction(
					  ref  = "coldbox.handler"
					, args = { event=preHandler.event, args=preHandler.args ?: {} }
				);
			}
		}

		if ( IsStruct( arguments.result.appendState ?: "" ) && !StructIsEmpty( arguments.result.appendState ) ) {
			arguments.cfflowResult.addPostFunction(
				  ref  = "coldbox.handler"
				, args = { event="admin.datamanagerWorkflow._appendStatePostFunction", args={ state=arguments.result.appendState } }
			);
		}

		for( var postHandler in postHandlers ) {
			if ( Len( Trim( postHandler.event ?: "" ) ) ) {
				arguments.cfflowResult.addPostFunction(
					  ref  = "coldbox.handler"
					, args = { event=postHandler.event, args=postHandler.args ?: {} }
				);
			}
		}

	}

	private function _convertAction( action, cfflowAction, stepId="" ) {
		if ( !StructIsEmpty( arguments.action.condition ?: {} ) ) {
			arguments.cfflowAction.setCondition( cfflowFactory.getCondition( argumentCollection=action.condition ) );
		}

		arguments.cfflowAction.setDefaultResult( id="default", isDefault=true, joins=( arguments.action.result.joins ?: [] ) );
		_convertResultTransitions( arguments.action.result, arguments.cfflowAction.getDefaultResult(), arguments.stepId );
		_convertResultFunctions( arguments.action.result, arguments.cfflowAction.getDefaultResult() );

		var conditionalResults = arguments.action.conditionalResults ?: [];
		for( var res in conditionalResults ) {
			var condResult = arguments.cfflowAction.addConditionalResult(
				  id        = res.id
				, isDefault = false
				, joins     = ( res.joins ?: [] )
				, condition = cfflowFactory.getCondition( argumentCollection=res.condition ?: {} )
			);

			_convertResultTransitions( res, condResult, arguments.stepId );
			_convertResultFunctions( res, condResult );
		}
	}

	private function _convertStep( flow, step ) {
		var cfflowStep = arguments.flow.addStep( id=arguments.step.id );
		var actions    = arguments.step.actions ?: [];

		for( var action in actions ) {
			_convertAction(
				  action       = action
				, stepId       = arguments.step.id
				, cfflowAction = cfflowStep.addAction( id=action.id, isAutomatic=$helpers.isTrue( action.auto ?: "" ) )
			);
		}
	}

	private function _convertJoin( flow, join ) {
		var cfflowJoin = flow.addJoin( id=join.id, steps=join.waitForSteps );

		cfflowJoin.setDefaultResult( id="default", isDefault=true, joins=( arguments.join.result.joins ?: [] ) );
		_convertResultTransitions( arguments.join.result, cfflowJoin.getDefaultResult() );
		_convertResultFunctions( arguments.join.result, cfflowJoin.getDefaultResult() );

		var conditionalResults = arguments.join.conditionalResults ?: [];
		for( var res in conditionalResults ) {
			var condResult = cfflowJoin.addConditionalResult( id=res.id, isDefault=false, joins=( res.joins ?: [] ) );
			_convertResultTransitions( res, condResult );
			_convertResultFunctions( res, condResult );
		}
	}

}