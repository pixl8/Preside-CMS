/**
 * @feature        webflow
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	/**
	 * @webflowLibrary.inject  webflowSpecLibrary
	 * @actionsService.inject  webflowActionsService
	 * @instanceService.inject webflowInstanceService
	 * @configService.inject   webflowConfigurationService
	 *
	 */
	public any function init(
		  required any webflowLibrary
		, required any actionsService
		, required any instanceService
		, required any configService
	) {
		_setWebflowLibrary( arguments.webflowLibrary );
		_setActionsService( arguments.actionsService );
		_setInstanceService( arguments.instanceService );
		_setConfigService( arguments.configService );

		return this;
	}

// PUBLIC API METHODS
	public boolean function doNext( required string webflowId, required string instanceRef, required string subReference, required string stepId, struct explicitArgs={} ) {
		var wfInstance = _getInstanceService().getInstance( webflowId=arguments.webflowId, instanceRef=arguments.instanceRef, subReference=arguments.subReference, explicitArgs=arguments.explicitArgs );
		if ( IsNull( local.wfInstance ) ) {
			wfInstance = _getInstanceService().createInstance( webflowId=arguments.webflowId, instanceRef=arguments.instanceRef, subReference=arguments.subReference, explicitArgs=arguments.explicitArgs );
		}

		_validateNextIsPossible(
			  stepId   = arguments.stepId
			, instance = local.wfInstance ?: NullValue()
		);

		var step             = _getWebflowLibrary().getWebflowStep( arguments.webflowId, arguments.stepId );
		var formData         = $getRequestContext().getCollectionForForm();
		var submissionConfig = step.getSubmission();
		var autoValidate     = this.$helpers.isTrue( submissionConfig.autoValidateForms ?: true );
		var validationResult = autoValidate ? this.$helpers.validateForms( formData ) : $newValidationResult();
		var actionEvent      = submissionConfig.handler.event ?: "webflow.#arguments.webflowId#.#arguments.stepId#Action";
		var handlerResult    = true;
		var persistData      = $getRequestContext().getCollectionWithoutSystemVars();
		StructAppend( persistData, formData );

		if ( Len( Trim( actionEvent ) ) && $getColdbox().handlerExists( actionEvent ) ) {
			var configService = _getConfigService();
			var flowConfig = configService.getFlowConfig(
				  webflowId   = arguments.webflowId
				, instanceRef = arguments.instanceRef
			);
			var stepConfig = configService.getStepConfig(
				  webflowId   = arguments.webflowId
				, stepId      = arguments.stepId
				, instanceRef = arguments.instanceRef
			);

			handlerResult = $getColdbox().runEvent(
				  event          = actionEvent
				, private        = true
				, prePostExempt  = true
				, eventArguments = {
					  args             = submissionConfig.handler.args ?: {}
					, wfInstance       = wfInstance
					, webflowId        = arguments.webflowId
					, instanceRef      = arguments.instanceRef
					, stepId           = arguments.stepId
					, webflowConfig    = flowConfig
					, stepConfig       = stepConfig
					, persistData      = persistData
					, validationResult = validationResult
				  }
			);

			if ( IsNull( local.handlerResult ) ) {
				handlerResult = true;
			}
		}

		if ( validationResult.validated() && handlerResult ) {
			wfInstance.appendState( persistData );

			try {
				wfInstance.doAction( "next", arguments.stepId );
			} catch( any e ) {
				$raiseError( e );

				validationResult.setGeneralMessage( $translateResource( "webflow:error.unexpected.submission.error" ) );

				wfInstance.appendState( { _webflowTransitionError={ "#arguments.stepId#" = {
					  type    = e.type    ?: ""
					, message = e.message ?: ""
					, detail  = e.detail  ?: ""
				} } } );
			}
		}
		if ( !validationResult.validated() || !handlerResult ) {
			persistData.validationResult = validationResult;

			$getColdbox().getRequestService().getFlashScope().putAll( map=persistData, saveNow=true );
		}

		return true;
	}

	public boolean function doPrev( required string webflowId, required string instanceRef, required string subReference, required string stepId, struct explicitArgs={} ) {
		var instance = _getInstanceService().getInstance( webflowId=arguments.webflowId, instanceRef=arguments.instanceRef, subReference=arguments.subReference, explicitArgs=arguments.explicitArgs );
		if ( IsNull( local.instance ) ) {
			instance = _getInstanceService().createInstance( webflowId=arguments.webflowId, subReference=arguments.subReference, instanceRef=arguments.instanceRef );
		}
		_validatePrevIsPossible(
			  stepId   = arguments.stepId
			, instance = local.instance ?: NullValue()
		);

		if ( !_runBackHandler( argumentCollection=arguments, wfInstance=instance ) ) {
			return false;
		}

		instance.doAction( "prev", arguments.stepId );

		return true;
	}

	public boolean function doCancel(  required string webflowId, required string instanceRef, required string subReference, required string stepId, struct explicitArgs={}  ) {
		var wfInstance = _getInstanceService().getInstance( webflowId=arguments.webflowId, instanceRef=arguments.instanceRef, subReference=arguments.subReference, explicitArgs=arguments.explicitArgs );

		_validateCancelIsPossible(
			  webflowId = arguments.webflowId
			, instance  = local.wfInstance ?: NullValue()
		);

		var webflow    = _getWebflowLibrary().getWebflow( webflowId );
		var preCancel  = webflow.getPreCancelHandler();
		var postCancel = webflow.getPostCancelHandler();

		if ( Len( preCancel.event ?: "" ) ) {
			$runEvent(
				  event          = preCancel.event
				, private        = true
				, prePostExempt  = true
				, eventArguments = {
					  args       = preCancel.args ?: {}
					, wfInstance = wfInstance ?: NullValue()
				}
			);
		}

		// todo some kind of official cancellation for tracking
		if ( !IsNull( local.wfInstance ) ) {
			_getInstanceService().completeAndArchiveWebflow( wfInstance );
		}

		if ( Len( postCancel.event ?: "" ) ) {
			$runEvent(
				  event          = postCancel.event
				, private        = true
				, prePostExempt  = true
				, eventArguments = {
					  args       = postCancel.args ?: {}
					, wfInstance = wfInstance ?: NullValue()
				}
			);
		}

		return true;
	}

	public boolean function backToStep(
		  required string webflowId
		, required string instanceRef
		, required string subReference
		, required string currentStepId
		, required string backToStepId
	) {
		var instance = _getInstanceService().getInstance( webflowId=arguments.webflowId, instanceRef=arguments.instanceRef, subReference=arguments.subReference );
		if ( IsNull( local.instance ) ) {
			instance = _getInstanceService().createInstance( webflowId=arguments.webflowId, instanceRef=arguments.instanceRef, subReference=arguments.subReference );
		}

		var done               = true;
		var currentStepChanged = false;
		var currentStep        = arguments.currentStepId;
		var newActiveStep      = "";

		_validateBackToStepIsPossible(
			  currentStepId = arguments.currentStepId
			, backToStepId  = arguments.backToStepId
			, instance      = local.instance ?: NullValue()
		);

		do {
			try {
				doPrev( webflowId, instanceRef, subReference, currentStep );
			} catch( any e ) {
				break;
			}

			newActiveStep      = instance.getActiveStep();
			currentStepChanged = currentStep != newActiveStep;
			currentStep        = newActiveStep;
		} while( currentStepChanged && currentStep != backToStepId );

		return newActiveStep == backToStepId;
	}

	public string function getFirstStep( required WorkflowInstance wfInstance ) {
		var stepStatuses = wfInstance.getAllStepStatuses();

		for( var step in stepStatuses ) {
			if ( step.status == "complete" ) {
				return step.step;
			}
		}

		return wfInstance.getActiveStep();
	}


// PRIVATE HELPERS
	private void function _validateNextIsPossible(
		  required string stepId
		,          any    instance
	) {
		if ( IsNull( arguments.instance ) ) {
			throw( "Cannot 'doNext' on workflow as there is no active workflow instance.", "preside.webflow.instance.not.active" );
		}
		if ( instance.getActiveStep() != arguments.stepId ) {
			throw( "Cannot 'doNext' on workflow as the currently active step does not match the passed step ID.", "preside.webflow.step.not.active" );
		}
		if ( !_getActionsService().hasNextAction( instance ) ) {
			throw( "Cannot 'doNext on workflow as the currently active step does not have a 'next' action.", "preside.webflow.action.not.permitted" );
		}
	}

	private void function _validatePrevIsPossible(
		  required string stepId
		,          any    instance
	) {
		if ( IsNull( arguments.instance ) ) {
			throw( "Cannot 'doPrev' on workflow as there is no active workflow instance.", "preside.webflow.instance.not.active" );
		}
		if ( instance.getActiveStep() != arguments.stepId ) {
			throw( "Cannot 'doPrev' on workflow as the currently active step does not match the passed step ID.", "preside.webflow.step.not.active" );
		}
		if ( !_getActionsService().hasPrevAction( instance ) ) {
			throw( "Cannot 'doPrev on workflow as the currently active step does not have a 'next' action.", "preside.webflow.action.not.permitted" );
		}
	}

	private void function _validateBackToStepIsPossible(
		  required string currentStepId
		, required string backToStepId
		,          any    instance
	) {
		if ( IsNull( arguments.instance ) ) {
			throw( "Cannot 'backToStep' on workflow as there is no active workflow instance.", "preside.webflow.instance.not.active" );
		}
		if ( instance.getActiveStep() != arguments.currentStepId ) {
			throw( "Cannot 'backToStep' on workflow as the currently active step does not match the passed step ID.", "preside.webflow.step.not.active" );
		}

		var stepStatuses = instance.getAllStepStatuses();
		for( var step in stepStatuses ) {
			if ( step.step == arguments.backToStepId ) {
				if ( step.status == "complete" ) {
					return;
				}
				break;
			}
		}

		throw( "Cannot 'backToStep' on workflow as the passed step has not already been completed.", "preside.webflow.step.not.completed" );
	}

	private void function _validateCancelIsPossible( required string webflowId, any instance ) {
		if ( IsNull( arguments.instance ) ) {
			return;
		}

		var step = _getWebflowLibrary().getWebflowStep( arguments.webflowId, arguments.instance.getActiveStep() );

		if ( !step.getCanCancel() ) {
			throw( "Cannot 'cancel' the current webflow as the active step is not configured to be cancellable.", "preside.webflow.instance.not.cancellable" );
		}
	}

	private boolean function _runBackHandler(
		  required string webflowId
		, required string instanceRef
		, required string subReference
		, required string stepId
		, required any    wfInstance
		,          struct explicitArgs={}
	) {
		var submissionConfig = _getWebflowLibrary().getWebflowStep( arguments.webflowId, arguments.stepId ).getSubmission();
		var actionEvent      = submissionConfig.backHandler.event ?: "";

		if ( !Len( Trim( actionEvent ) ) ) {
			return true;
		}

		var args = submissionConfig.backHandler.args ?: {};
		StructAppend( args, arguments.explicitArgs );

		var handlerResult = $getColdbox().runEvent(
			  event          = actionEvent
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				  args          = args
				, wfInstance    = arguments.wfInstance
				, webflowId     = arguments.webflowId
				, instanceRef   = arguments.instanceRef
				, stepId        = arguments.stepId
				, webflowConfig = _getConfigService().getFlowConfig( webflowId=arguments.webflowId, instanceRef=arguments.instanceRef )
				, stepConfig    = _getConfigService().getStepConfig( webflowId=arguments.webflowId, stepId=arguments.stepId, instanceRef=arguments.instanceRef )
			  }
		);

		return !IsBoolean( local.handlerResult ?: "" ) || handlerResult;
	}

// GETTERS AND SETTERS
	private any function _getWebflowLibrary() {
	    return _webflowLibrary;
	}
	private void function _setWebflowLibrary( required any webflowLibrary ) {
	    _webflowLibrary = arguments.webflowLibrary;
	}

	private any function _getActionsService() {
	    return _actionsService;
	}
	private void function _setActionsService( required any actionsService ) {
	    _actionsService = arguments.actionsService;
	}

	private any function _getInstanceService() {
	    return _instanceService;
	}
	private void function _setInstanceService( required any instanceService ) {
	    _instanceService = arguments.instanceService;
	}

	private any function _getConfigService() {
	    return _configService;
	}
	private void function _setConfigService( required any configService ) {
	    _configService = arguments.configService;
	}
}