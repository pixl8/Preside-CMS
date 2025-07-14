/**
 * @feature        webflow
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	/**
	 * @webflowLibrary.inject        webflowSpecLibrary
	 * @webflowConfigurator.inject   webflowConfigurationService
	 * @cfflow.inject                cfflow@cfflow
	 * @cfFlowFactory.inject         workflowFactory@cfflow
	 * @cookieService.inject         cookieService
	 * @websiteVisitorService.inject websiteVisitorService
	 * @cfFlowPresideStorage.inject  cfFlowPresideStorage
	 *
	 */
	public any function init(
		  required any webflowLibrary
		, required any webflowConfigurator
		, required any cfflow
		, required any cfFlowFactory
		, required any cookieService
		, required any websiteVisitorService
		, required any cfFlowPresideStorage
	) {
		_setWebflowLibrary( arguments.webflowLibrary );
		_setWebflowConfigurator( arguments.webflowConfigurator );
		_setCfFlow( arguments.cfflow );
		_setCfFlowFactory( arguments.cfFlowFactory );
		_setCookieService( arguments.cookieService );
		_setWebsiteVisitorService( arguments.websiteVisitorService );
		_setCfFlowPresideStorage( arguments.cfFlowPresideStorage );

		return this;
	}

// PUBLIC API METHODS
	public boolean function instanceExists( required string webflowId, string instanceRef="", string subReference="", struct explicitArgs={}, string archiveId="" ) {
		try {
			var webflow = _getWebflowLibrary().getWebflow( arguments.webflowId );
			var args    = getInstanceArgs( argumentCollection=arguments );

			if ( Len( arguments.archiveId ) ) {
				args.archiveId = arguments.archiveId;
			}

			return _getCfflow().instanceExists(
				  workflowId   = webflow.getCfFlowId()
				, instanceArgs = args
			);
		} catch( cfflow.workflow.does.not.exist e ) {
			$raiseError( e );

			return false;
		} catch( preside.webflow.not.found e ) {
			$raiseError( e );

			return false;
		}
	}

	public any function getInstance( required string webflowId, string instanceRef="", string subReference="", struct explicitArgs={}, string archiveId="" ) {
		try {
			var webflow = _getWebflowLibrary().getWebflow( arguments.webflowId );
			var args    = getInstanceArgs( argumentCollection=arguments );

			if ( Len( arguments.archiveId ) ) {
				args.archiveId = arguments.archiveId;
			}

			return _getCfflow().getInstance(
				  workflowId   = webflow.getCfFlowId()
				, instanceArgs = args
			);
		} catch( cfflow.workflow.does.not.exist e ) {
			$raiseError( e );

			return nullValue();
		} catch( preside.webflow.not.found e ) {
			$raiseError( e );

			return nullValue();
		}
	}

	public any function createInstance( required string webflowId, string instanceRef="", string subReference="", struct explicitArgs={}, struct initialState={}, string initialActionId, boolean lazyLoad=false ) {
		if ( !_sessionsEnabled() ) {
			// stateless requests do not get to have instances
			return;
		}

		try {
			var webflow = _getWebflowLibrary().getWebflow( arguments.webflowId );
			var args    = getInstanceArgs( argumentCollection=arguments, createVisitorIfNotExists=!arguments.lazyLoad );

			if ( arguments.lazyLoad ) {
				args.lazyLoad = true;
			}

			var webflowInit = webflow.getInit();
			var stateInit   = webflowInit.state ?: "";
			var initState   = {};

			if ( IsStruct( stateInit.args ?: "" ) && StructCount( stateInit.args ) ) {
				initState = stateInit.args;
			}

			if ( Len( Trim( stateInit.handler.event ?: "" ) ) ) {
				var stateArgs = {
					  args         = stateInit.handler.args ?: {}
					, webflowId    = arguments.webflowId
					, instanceRef  = arguments.instanceRef
					, subReference = arguments.subReference
					, webflow      = webflow
				};

				StructAppend( stateArgs.args, arguments.explicitArgs );
				var handlerState = $runEvent(
					  event          = stateInit.handler.event
					, private        = true
					, prepostExempt  = true
					, eventArguments = stateArgs
				);

				if ( IsStruct( local.handlerState ?: "" ) && StructCount( handlerState ) ) {
					StructAppend( initState, handlerState );
				}
			}
			StructAppend( arguments.initialState, initState );
			var instance = _getCfflow().createInstance(
				  workflowId      = webflow.getCfFlowId()
				, instanceArgs    = args
				, initialState    = arguments.initialState
				, initialActionId = arguments.initialActionId ?: NullValue()
			);

			var initCondition = webflowInit.condition ?: {};
			if ( StructCount( initCondition ) ) {
				var canStart = _getCfflow().getWorkflowEngine().evaluateCondition(
					  wfCondition = _getCfFlowFactory().getCondition( argumentCollection=initCondition )
					, wfInstance  = instance
				);

				if ( !canStart ) {
					if ( !arguments.lazyLoad ) {
						_getCfFlowPresideStorage().deleteInstance(
							  workflowId   = instance.getWorkflowId()
							, instanceArgs = instance.getInstanceArgs()
						);
					}
					return;
				}
			}

			return instance;
		} catch( cfflow.workflow.does.not.exist e ) {
			$raiseError( e );

			return;
		} catch( preside.webflow.not.found e ) {
			$raiseError( e );

			return;
		}
	}

	public struct function getInstanceArgs(
		  required string  webflowId
		,          string  instanceRef              = ""
		,          string  subReference             = ""
		,          struct  explicitArgs             = {}
		,          boolean createVisitorIfNotExists = false
	) {
		var webflow           = _getWebflowLibrary().getWebflow( arguments.webflowId );
		var flowConfig        = _getWebflowConfigurator().getFlowConfig( webflowId=arguments.webflowId, instanceRef=arguments.instanceRef );
		var initConfiguration = webflow.getInit();
		var configuredArgs    = initConfiguration.instanceargs.args ?: {};
		var handler           = initConfiguration.instanceargs.handler ?: {};
		var instanceArgs      = {};

		StructAppend( instanceArgs, configuredArgs );

		if ( Len( Trim( handler.event ?: "" ) ) && $getColdbox().handlerExists( handler.event ) ) {
			var argsFromHandler = {};
			var eventArgs = {
				  instanceArgs = {}
				, args         = {}
				, webflowId    = arguments.webflowId
				, instanceRef  = arguments.instanceRef
				, config       = flowConfig
			};

			StructAppend( eventArgs.args, handler.args ?: {} );
			StructAppend( eventArgs.args, explicitArgs );
			StructAppend( eventArgs.instanceArgs, configuredArgs );

			argsFromHandler = $runEvent(
				  event          = handler.event
				, private        = true
				, prePostExempt  = true
				, eventArguments = eventArgs
			);

			if ( !IsNull( local.argsFromHandler ) && IsStruct( argsFromHandler ) ) {
				StructAppend( instanceArgs, argsFromHandler );
			}
		}

		StructAppend( instanceArgs, arguments.explicitArgs );

		instanceArgs.owner           = instanceArgs.owner           ?: getDefaultOwner( createVisitorIfNotExists=arguments.createVisitorIfNotExists );
		instanceArgs.reference       = instanceArgs.reference       ?: arguments.webflowId;
		instanceArgs.subreference    = instanceArgs.subreference    ?: arguments.instanceRef;
		instanceArgs.subSubReference = instanceArgs.subSubReference ?: arguments.subReference ?: "";

		return instanceArgs;
	}

	public string function getDefaultOwner( boolean createVisitorIfNotExists=false ) {
		var userId = $getWebsiteLoggedInUserId();
		var visitorId = _getCookieService().getVar( name="vid", default="" );

		if ( !Len( Trim( userId ) ) ) {
			userId = visitorId;
			if ( !Len( Trim( userId ) ) && arguments.createVisitorIfNotExists ) {
				userId = _getWebsiteVisitorService().getVisitorId();
			}
		} else if ( Len( Trim( visitorId ) ) ) {
			_getCfFlowPresideStorage().transferOwner( visitorId, userId );
		}

		return userId
	}

	public string function completeAndArchiveWebflow( required WorkflowInstance wfInstance ) {
		if ( !wfInstance.isComplete() ) {
			wfInstance.setComplete();
		}
		return _getCfFlowPresideStorage().archiveInstance(
			  workflowId    = wfInstance.getWorkflowId()
			, instanceArgs  = wfInstance.getInstanceArgs()
			, archiveReason = "complete"
		);
	}

	public string function archiveCompleteWebflow( required string webflowId, string instanceRef="", string subReference="" ) {
		var instance = getInstance( argumentCollection=arguments );
		if ( !IsNull( local.instance ) && instance.isComplete() ) {
			return _getCfFlowPresideStorage().archiveInstance(
				  workflowId    = instance.getWorkflowId()
				, instanceArgs  = instance.getInstanceArgs()
				, archiveReason = "complete"
			);
		}

		return "";
	}

	public void function deleteBrokenInstance( required any wfInstance ) {
		_getCfFlowPresideStorage().deleteInstance(
			  workflowId    = arguments.wfInstance.getWorkflowId()
			, instanceArgs  = arguments.wfInstance.getInstanceArgs()
		);
	}

	public boolean function isInstanceTimedOut(
		  required string           webflowId
		,          string           instanceRef  = ""
		,          string           subReference = ""
		,          WorkflowInstance instance     = getInstance( webflowId=arguments.webflowId, instanceRef=arguments.instanceRef, subReference=arguments.subReference )
	) {
		var config           = _getWebflowConfigurator().getFlowConfig( arguments.webflowId, arguments.instanceRef );
		var timeoutInMinutes = Val( config.timeout_in_minutes ?: "" );

		if ( !timeoutInMinutes ) {
			return false;
		}

		if ( IsNull( arguments.instance ) ) {
			return false;
		}

		var lastModified = _getCfFlowPresideStorage().getLastModified(
			  workflowId    = arguments.instance.getWorkflowId()
			, instanceArgs  = arguments.instance.getInstanceArgs()
		);

		return IsDate( lastModified ?: "" ) && DateDiff( "n", lastModified, Now() ) >= timeoutInMinutes;
	}

	public boolean function archiveWorkflow(
		  required string webflowId
		,          string instanceRef   = ""
		,          string subReference  = ""
		,          struct explicitArgs  = {}
		,          string archiveReason = "timedout"
	) {
		var instance = getInstance( argumentCollection=arguments );

		if ( IsNull( local.instance ) || ( ( arguments.archiveReason == "timedout" ) && !isInstanceTimedOut( argumentCollection=arguments, instance=instance ) ) ) {
			return false;
		}

		var state = instance.getState();
		var steps = _getCfFlowPresideStorage().getAllStepStatuses(
			  workflowId    = instance.getWorkflowId()
			, instanceArgs  = instance.getInstanceArgs()
		);

		if ( StructIsEmpty( state ) && StructCount( steps ) == 1 ) {
			_getCfFlowPresideStorage().deleteInstance(
				  workflowId    = instance.getWorkflowId()
				, instanceArgs  = instance.getInstanceArgs()
			);
		} else {
			_getCfFlowPresideStorage().archiveInstance(
				  workflowId    = instance.getWorkflowId()
				, instanceArgs  = instance.getInstanceArgs()
				, archiveReason = arguments.archiveReason
			);
		}

		return true;
	}

	public boolean function archiveExpiredWorkflow( required string webflowId, string instanceRef="", string subReference="" ) {
		return archiveWorkflow( argumentCollection=arguments );
	}

	public boolean function currentStepIgnoresExpiryOnSubmission( required string webflowId, string instanceRef="", string subReference="") {
		var instance = getInstance( argumentCollection=arguments );
		if ( isNull( local.instance ) ) {
			return false;
		}
		var step = instance.getActiveStep();

		if ( Len( step ) ) {
			try {
				step = _getWebflowLibrary().getWebflowStep(
					  webflowId = arguments.webflowId
					, stepId = step
				);
			} catch( preside.webflow.step.not.found e ) {
				return false;
			}

			return step.getIgnoreTimeout();
		}

		return false;
	}


// PRIVATE HELPERS
	private boolean function _sessionsEnabled() {
		var appSettings = getApplicationSettings();

		return !IsBoolean( appSettings.statelessRequest ?: "" ) || !appSettings.statelessRequest;
	}


// GETTERS AND SETTERS
	private any function _getWebflowLibrary() {
	    return _webflowLibrary;
	}
	private void function _setWebflowLibrary( required any webflowLibrary ) {
	    _webflowLibrary = arguments.webflowLibrary;
	}

	private any function _getWebflowConfigurator() {
	    return _webflowConfigurator;
	}
	private void function _setWebflowConfigurator( required any webflowConfigurator ) {
	    _webflowConfigurator = arguments.webflowConfigurator;
	}

	private any function _getCfflow() {
	    return _cfflow;
	}
	private void function _setCfflow( required any cfflow ) {
	    _cfflow = arguments.cfflow;
	}

	private any function _getCfFlowFactory() {
	    return _cfFlowFactory;
	}
	private void function _setCfFlowFactory( required any cfFlowFactory ) {
	    _cfFlowFactory = arguments.cfFlowFactory;
	}

	private any function _getCookieService() {
	    return _cookieService;
	}
	private void function _setCookieService( required any cookieService ) {
	    _cookieService = arguments.cookieService;
	}

	private any function _getWebsiteVisitorService() {
	    return _websiteVisitorService;
	}
	private void function _setWebsiteVisitorService( required any websiteVisitorService ) {
	    _websiteVisitorService = arguments.websiteVisitorService;
	}

	private any function _getCfFlowPresideStorage() {
	    return _cfFlowPresideStorage;
	}
	private void function _setCfFlowPresideStorage( required any cfFlowPresideStorage ) {
	    _cfFlowPresideStorage = arguments.cfFlowPresideStorage;
	}

}