/**
 * @feature        webflow
 * @presideService true
 * @singleton      true
 */
component {

	variables._flows = {};
	variables._steps = {};

// CONSTRUCTOR
	/**
	 * @cfflowFactory.inject workflowFactory@cfflow
	 */
	public any function init( required any cfflowFactory ) {
		_setCfFlowFactory( arguments.cfflowFactory );

		return this;
	}

// PUBLIC API METHODS
	public Workflow function convert( required Webflow flow ) {
		var webflowSteps  = arguments.flow.getSteps();
		var convertedFlow = _getCfFlowFactory().getWorkflow(
			  id    = arguments.flow.getCfFlowId()
			, class = "preside.standard.flow"
			, meta  = arguments.flow.getMeta()
		);

		_setupCfFlowInitialAction( convertedFlow, webflowSteps );

		for( var i=1; i<=webflowSteps.len(); i++ ) {
			_convertWebflowStepToCfFlowStep( convertedFlow, webflowSteps, i );
		}

		return convertedFlow;
	}

// PRIVATE HELPERS
	private void function _setupCfFlowInitialAction( required Workflow convertedFlow, required array webflowSteps ) {
		var initialAction = arguments.convertedFlow.addInitialAction( id="start", isAutomatic=true );
		var defaultStep = "";
		var factory = _getCfFlowFactory();
		var conditionalSteps = [];
		var conditionalStepIds = [];
		var hasExplicitStartSteps = false;

		for( var step in arguments.webflowSteps ) {
			if ( step.getStart() ) {
				hasExplicitStartSteps = true;

				if ( step.hasCondition() ) {
					conditionalSteps.append( step );
					conditionalStepIds.append( step.getId() );
				} else {
					defaultStep = step.getId();
				}
			}
		}

		if ( !hasExplicitStartSteps ) {
			for( var step in arguments.webflowSteps ) {
				if ( step.hasCondition() ) {
					conditionalSteps.append( step );
					conditionalStepIds.append( step.getId() );
				} else {
					defaultStep = step.getId();
					break;
				}
			}
		}

		if ( conditionalSteps.len() ) {
			for( var conditionalStep in conditionalSteps ) {
				var condition = factory.getCondition( argumentCollection=conditionalStep.getCondition() );
				var result = initialAction.addConditionalResult( id=conditionalStep.getId(), condition=condition );
				var otherSteps = [];

				for( var otherStep in conditionalSteps ) {
					if ( otherStep.getId() != conditionalStep.getId () ) {
						otherSteps.append( otherStep.getId() );
					} else if ( !hasExplicitStartSteps ) {
						break;
					}
				}
				if ( hasExplicitStartSteps && Len( defaultStep ) ) {
					otherSteps.append( defaultStep );
				}
				_addPreFunctionsToResult(
					  webflowSteps     = arguments.webFlowSteps
					, result           = result
					, activeStep       = conditionalStep.getId()
				);
				_addTransitionsToResult(
					  webflowSteps     = arguments.webFlowSteps
					, result           = result
					, activeStep       = conditionalStep.getId()
					, conditionalSteps = otherSteps
					, direction        = "next"
				);
			}
		}

		if ( Len( defaultStep ) ) {
			initialAction.setDefaultResult( id=defaultStep );
			_addPreFunctionsToResult(
				  webflowSteps     = arguments.webFlowSteps
				, result           = initialAction.getDefaultResult()
				, activeStep       = defaultStep
			);
			_addTransitionsToResult(
				  webflowSteps     = arguments.webFlowSteps
				, result           = initialAction.getDefaultResult()
				, activeStep       = defaultStep
				, conditionalSteps = conditionalStepIds
				, direction        = "next"
			);
		}
	}

	private void function _convertWebflowStepToCfFlowStep(
		  required any     convertedFlow
		, required array   webflowSteps
		, required numeric webflowStepIndex
	) {
		var webflowStep = arguments.webflowSteps[ arguments.webflowStepIndex ];
		var cfflowStep  = arguments.convertedFlow.addStep( id=webflowStep.getId() );
		var moreSteps   = !webflowStep.getFinish() && arguments.webflowStepIndex < ArrayLen( arguments.webflowSteps );
		var prevSteps   = ( !webflowStep.getStart() && arguments.webflowStepIndex > 1 ) || ArrayLen( webflowStep.getPrev() );

		if ( moreSteps ) {
			if ( prevSteps ) {
				_addPreviousAction( argumentCollection=arguments, cfflowStep=cfflowStep );
			}
			_addNextAction( argumentCollection=arguments, cfflowStep=cfflowStep );
		}
	}

	private void function _addPreviousAction(
		  required any     convertedFlow
		, required array   webflowSteps
		, required numeric webflowStepIndex
		, required any     cfflowStep
	) {
		var prevAction           = arguments.cfflowStep.addAction( id="prev", isAutomatic=false );
		var conditionalPrevSteps = [];
		var factory              = _getCfFlowFactory();
		var prevSteps            = _getPrevSteps( arguments.webflowSteps, arguments.webflowStepIndex );
		var noDefaultStep        = IsSimpleValue( prevSteps.default );
		var noConditionalSteps   = !ArrayLen( prevSteps.conditional );
		var thisStep             = arguments.webflowSteps[ arguments.webflowStepIndex ];

		if ( noDefaultStep ) {
			if ( noConditionalSteps ) {
				return;
			}

			prevAction.setCondition( _getConditionFromConditionalSteps( prevSteps.conditional ) );
			prevSteps.default = ArrayLast( prevSteps.conditional );
			prevSteps.conditional.deleteAt( prevSteps.conditional.len() );
		}

		for( var prevStep in prevSteps.conditional ) {
			var condition         = factory.getCondition( argumentCollection=prevStep.getCondition() );
			var conditionalResult = prevAction.addConditionalResult( id=prevStep.getId(), condition=condition );

			_addPreFunctionsToResult(
				  webflowSteps     = arguments.webFlowSteps
				, result           = conditionalResult
				, activeStep       = prevStep.getId()
				, parentStep       = thisStep
				, direction        = "back"
			);

			_addTransitionsToResult(
				  webflowSteps     = arguments.webFlowSteps
				, result           = conditionalResult
				, currentStep      = arguments.webflowStepIndex
				, activeStep       = prevStep.getId()
				, conditionalSteps = conditionalPrevSteps
				, direction        = "prev"
			);

			conditionalPrevSteps.append( prevStep.getId() );
		}

		prevAction.setDefaultResult( id=prevSteps.default.getId() );
		_addPreFunctionsToResult(
			  webflowSteps     = arguments.webFlowSteps
			, result           = prevAction.getDefaultResult()
			, activeStep       = prevSteps.default.getId()
			, parentStep       = thisStep
			, direction        = "back"
		);
		_addTransitionsToResult(
			  webflowSteps     = arguments.webFlowSteps
			, result           = prevAction.getDefaultResult()
			, currentStep      = arguments.webflowStepIndex
			, activeStep       = prevSteps.default.getId()
			, conditionalSteps = conditionalPrevSteps
			, direction        = "prev"
		);
	}

	private void function _addNextAction(
		  required any     convertedFlow
		, required array   webflowSteps
		, required numeric webflowStepIndex
		, required any     cfflowStep
	) {
		var nextAction           = cfflowStep.addAction( id="next", isAutomatic=false );
		var conditionalNextSteps = [];
		var defaultStep          = "";
		var factory              = _getCfFlowFactory();
		var nextSteps            = _getNextSteps( arguments.webflowSteps, arguments.webflowStepIndex );

		for( var nextStep in nextSteps.conditional ) {
			var condition = factory.getCondition( argumentCollection=nextStep.getCondition() );
			var conditionalResult = nextAction.addConditionalResult( id=nextStep.getId(), condition=condition );

			_addPreFunctionsToResult(
				  webflowSteps     = arguments.webFlowSteps
				, result           = conditionalResult
				, activeStep       = nextStep.getId()
				, parentStep       = webflowSteps[ webflowStepIndex ]
			);
			_addTransitionsToResult(
				  webflowSteps     = arguments.webFlowSteps
				, result           = conditionalResult
				, currentStep      = arguments.webflowStepIndex
				, activeStep       = nextStep.getId()
				, conditionalSteps = conditionalNextSteps
				, direction        = "next"
			);

			conditionalNextSteps.append( nextStep.getId() );
		}

		nextAction.setDefaultResult( id=nextSteps.default.getId() );
		_addPreFunctionsToResult(
			  webflowSteps     = arguments.webFlowSteps
			, result           = nextAction.getDefaultResult()
			, activeStep       = nextSteps.default.getId()
			, parentStep       = webflowSteps[ webflowStepIndex ]
		);
		_addTransitionsToResult(
			  webflowSteps     = arguments.webFlowSteps
			, result           = nextAction.getDefaultResult()
			, currentStep      = arguments.webflowStepIndex
			, activeStep       = nextSteps.default.getId()
			, conditionalSteps = conditionalNextSteps
			, direction        = "next"
		);
	}

	private struct function _getNextSteps(
		  required array   webflowSteps
		, required numeric webflowStepIndex
	) {
		var currentStep           = arguments.webflowSteps[ arguments.webflowStepIndex ];
		var explicitNextStepIds   = currentStep.getNextSteps();
		var conditionalSteps      = [];
		var defaultStep           = "";
		var currentStepExitPoints = currentStep.getSubflowExitPointFor();

		if ( ArrayLen( explicitNextStepIds ) ) {
			for( var stepId in explicitNextStepIds ) {
				for( var step in arguments.webflowSteps ) {
					if ( step.getId() == stepId ) {
						if ( step.hasCondition() ) {
							conditionalSteps.append( step );
						} else if ( IsSimpleValue( defaultStep ) ) {
							defaultStep = step;
						} else {
							throw( "The webflow step, [#currentStep.getId()#], has more than one unconditional steps following it. All non-final steps must have one and only one unconditional step following them.", "preside.webflow.multiple.default.next.steps" );
						}
						break;
					}
				}
			}
		} else {
			for( var i=arguments.webflowStepIndex+1; i<=arguments.webflowSteps.len(); i++ ) {
				var step = arguments.webflowSteps[ i ];
				if ( ArrayFindNoCase( currentStepExitPoints, step.getSubflowRef() ) || ArrayFindNoCase( currentStepExitPoints, step.getParentSubflowRef() ) ) {
					continue; // do not go next when next step is within a subflow for which this step is an exit point
				}
				if ( step.hasCondition() ) {
					conditionalSteps.append( step );
				} else {
					defaultStep = step;
					break;
				}
			}
		}

		if ( IsSimpleValue( defaultStep ) ) {
			throw( "The webflow step, [#currentStep.getId()#], does not have any unconditional steps following it. All non-final steps must have one unconditional step following it in order for the flow to always be able to continue.", "preside.webflow.no.default.next.step" );
		}

		return {
			  conditional = conditionalSteps
			, default     = defaultStep
		};
	}

	private struct function _getPrevSteps(
		  required array   webflowSteps
		, required numeric webflowStepIndex
	) {
		var currentStep         = arguments.webflowSteps[ arguments.webflowStepIndex ];
		var explicitPrevStepIds = currentStep.getPrevSteps();
		var conditionalSteps    = [];
		var defaultStep         = "";

		if ( ArrayLen( explicitPrevStepIds ) ) {
			for( var stepId in explicitPrevStepIds ) {
				for( var step in arguments.webflowSteps ) {
					if ( step.getId() == stepId ) {
						if ( step.hasCondition() ) {
							conditionalSteps.append( step );
						} else {
							defaultStep = step;
						}
						break;
					}
				}
			}
		} else {
			for( var i=arguments.webflowStepIndex-1; i>0; i-- ) {
				var step = arguments.webflowSteps[ i ];
				if ( step.hasCondition() ) {
					conditionalSteps.append( step );
				} else {
					defaultStep = step;
					break;
				}
			}
		}

		return {
			  conditional = conditionalSteps
			, default     = defaultStep
		};
	}

	private void function _addTransitionsToResult(
		  required array   webflowSteps
		, required any     result
		, required string  activeStep
		, required array   conditionalSteps
		, required string  direction
		,          numeric currentStep = 0
	){
		var newCurrentStatus     = arguments.direction == "prev" ? "pending" : "complete";
		var newConditionalStatus = arguments.direction == "prev" ? "pending" : "skipped";

		if ( arguments.currentStep ) {
			arguments.result.addTransition( step=arguments.webflowSteps[ arguments.currentStep ].getId(), status=newCurrentStatus );
		}

		for( var i=1; i<=conditionalSteps.len(); i++ ) {
			arguments.result.addTransition( step=conditionalSteps[ i ], status=newConditionalStatus );
		}
		arguments.result.addTransition( step=activeStep, status="active" );
	}

	private void function _addPreFunctionsToResult(
		  required array   webflowSteps
		, required any     result
		, required string  activeStep
		,          any     parentStep
		,          string  direction = "forward"
	){
		for( var step in arguments.webflowSteps ) {
			if ( step.getId() == arguments.activeStep ) {
				var preActions = []

				if ( arguments.direction == "forward" ) {
					if ( StructKeyExists( arguments, "parentStep" ) ) {
						ArrayAppend( preActions, arguments.parentStep.getPostActions(), true );
					}
					ArrayAppend( preActions, step.getPreActions(), true );
				} else {
					ArrayAppend( preActions, step.getPreActions(), true );
					if ( StructKeyExists( arguments, "parentStep" ) ) {
						ArrayAppend( preActions, arguments.parentStep.getPostActions(), true );
					}
				}

				for( var preAction in preActions ) {
					var actionDir = preAction.direction ?: "forward";
					if ( actionDir != "both" && actionDir != arguments.direction ) {
						continue;
					}

					if ( Len( Trim( preAction.handler.event ?: "" ) ) ) {
						if ( StructCount( preAction.condition ?: {} ) ) {
							result.addPreFunction(
								  ref       = "coldbox.handler"
								, args      = { event=preAction.handler.event, args=preAction.handler.args ?: {} }
								, condition = _getCfFlowFactory().getCondition( argumentCollection=preAction.condition )
							);
						} else {
							result.addPreFunction(
								  ref  = "coldbox.handler"
								, args = { event=preAction.handler.event, args=preAction.handler.args ?: {} }
							);
						}
					}
				}

				break;
			}
		}
	}

	private WorkflowCondition function _getConditionFromConditionalSteps( required array steps ) {
		var condition = _getCfFlowFactory().getCondition( argumentCollection=steps[ 1 ].getCondition() );

		for( var i=2; i<=arguments.steps.len(); i++ ) {
			condition.addOrCondition( argumentCollection=arguments.steps[ i ].getCondition() );
		}

		return condition;
	}

// GETTERS AND SETTERS
	private any function _getCfFlowFactory() {
	    return _cfFlowFactory;
	}
	private void function _setCfFlowFactory( required any cfFlowFactory ) {
	    _cfFlowFactory = arguments.cfFlowFactory;
	}

}