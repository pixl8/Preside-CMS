/**
 * @feature        webflow
 * @presideService true
 * @singleton      true
 */
component {
	property name="plantUmlService" inject="plantUmlDiagramService";

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

	public string function renderFlowDiagram(
		  required string objectName
		, required string recordId
		,          string plantUmlStyles = _getDefaultPlantUmlStyles()
	) {
		return plantUmlService.umlToSvgDiagram( flowToPlantUml( argumentCollection=arguments ) );
	}

	public string function flowToPlantUml(
		  required string objectName
		, required string recordId
		,          string plantUmlStyles = _getDefaultPlantUmlStyles()
	) {
		var wfDetail = $getPresideObject( arguments.objectName ).selectData(
			  id           = arguments.recordId
			, returntype   = "singleRecordStruct"
			, selectFields =[
				  "id"
				, "owner"
				, "reference"
				, "sub_reference"
				, "sub_sub_reference"
			]
		);

		if ( !StructIsEmpty( wfDetail ) ) {
			var nl        = Chr( 10 );
			var plantUml  = "@startuml" & nl;
			var isArchive = ( arguments.objectName == "cfflow_workflow_archived_instance" );

			if ( Len( Trim( arguments.plantUmlStyles ) ) ) {
				plantUml &= arguments.plantUmlStyles & nl;
			}

			var wfInstance = getInstance(
				  webflowId    = wfDetail.reference
				, instanceRef  = wfDetail.sub_reference
				, subReference = wfDetail.sub_sub_reference
				, explicitArgs = { owner=wfDetail.owner }
				, archiveId    = isArchive ? wfDetail.id : ""
			);

			var allSteps       = !IsSimpleValue( wfInstance ?: "" ) ? wfInstance.getAllStepStatuses() : [];
			var stepTitles     = _getWebflowConfigurator().getStepTitles( webflowId=wfDetail.reference, instanceRef=wfDetail.sub_reference );
			var transitionsUml = "";
			var fromStep       = "";

			for( var step in allSteps ) {
				var stepId     = Trim( step.step ?: "" );
				var stepLabel  = StructKeyExists( stepTitles, stepId ) ? "#stepTitles[ stepId ]# (#stepId#)" : stepId;
				var stepStatus = $translateResource( uri="enum.cfflowStepStatus:#step.status#.label", defaultValue=step.status );

				plantUml &= 'state "#stepStatus#" as #stepId#<<#LCase( step.status )#>>: #stepLabel#' & nl;

				if ( !Len( fromStep ) ) {
					transitionsUml &= "[*] --> #stepId#" & nl;
				} else {
					transitionsUml &= "#fromStep# --> #stepId#" & nl;
				}

				fromStep = stepId;
			}

			transitionsUml &= "#fromStep# --> [*]" & nl;
			plantUml       &= transitionsUml & nl & "@enduml";

			return plantUml;
		}

		return "";
	}

	public query function getArchiveInstanceTransitions( required string archiveInstanceId ) {
		var processedTransitions = QueryNew( "from,action,to", "varchar,varchar,varchar" );
		var archiveTransitions   = $getPresideObject( "cfflow_workflow_archived_instance" ).selectData(
			  id           = arguments.archiveInstanceId
			, selectFields = [ "step_transitions" ]
			, returntype   = "singleValue"
			, columnKey    = "step_transitions"
		);

		if ( IsJSON( archiveTransitions ) ) {
			archiveTransitions = DeserializeJSON( archiveTransitions );

			var previousStep = "";
			for ( var transition in archiveTransitions ) {
				QueryAddRow( processedTransitions, {
					  from   = previousStep
					, action = transition.action
					, to     = transition.result
				} );

				previousStep = transition.result;
			}
		}

		return processedTransitions;
	}

	public struct function getWebflowTransitionsConfigForJourneyChart(
		  required string  webflowId
		,          string  webflowRef   = ""
		,          string  instanceRef  = ""
		,          string  statuses     = ""
		,          boolean isHistorical = false
		,          date    startDate
		,          date    endDate
	) {
		var pointLabels    = {};
		var transitions    = [];
		var transitionsMap = [:];
		var filters        = [ { filter={ reference=arguments.webflowId } } ];
		var flowConfig     = _getWebflowConfigurator().getFlowConfig( webflowId=arguments.webflowId, instanceRef=arguments.webflowRef );
		var stepLabels     = _getWebflowConfigurator().getStepLabels( webflowId=arguments.webflowId, instanceRef=arguments.webflowRef );
		var instanceQuery  = QueryNew( "" );

		if ( Len( arguments.instanceRef ) ) {
			ArrayAppend( filters, { filter={ sub_reference=arguments.instanceRef } } );
		}

		if ( StructKeyExists( arguments, "startDate" ) && IsDate( arguments.startDate ) ) {
			ArrayAppend( filters, {
				  filter       = "#arguments.isHistorical ? "date_archived" : "datecreated"# > :start"
				, filterParams = { start={ type="cf_sql_timestamp", value=arguments.startDate } }
			} );
		}
		if ( StructKeyExists( arguments, "endDate" ) && IsDate( arguments.endDate ) ) {
			ArrayAppend( filters, {
				  filter       = "#arguments.isHistorical ? "date_archived" : "datecreated"# < :end"
				, filterParams = { end={ type="cf_sql_timestamp", value=arguments.endDate } }
			} );
		}

		if ( arguments.isHistorical ) {
			if ( Len( arguments.statuses ) ) {
				ArrayAppend( filters, { filter={ archive_reason=ListToArray( arguments.statuses ) } } );
			}

			instanceQuery = $getPresideObject( "cfflow_workflow_archived_instance" ).selectData(
				  extraFilters = filters
				, selectFields = [ "id" ]
			);
		} else {
			if ( Len( arguments.statuses ) ) {
				if ( arguments.statuses == "active" ) {
					ArrayAppend( filters, {
						  filter       = "datemodified < :datemodified"
						, filterParams = { datemodified = DateAdd( "n", -1 * Val( flowConfig?.timeout_in_minutes ), Now() ) }
					} );
				}

				if ( arguments.statuses == "activetimedout" ) {
					ArrayAppend( filters, {
						  filter       = "datemodified >= :datemodified"
						, filterParams = { datemodified = DateAdd( "n", -1 * Val( flowConfig?.timeout_in_minutes ), Now() ) }
					} );
				}
			}

			instanceQuery = $getPresideObject( "cfflow_workflow_instance" ).selectData(
				  extraFilters = filters
				, selectFields = [ "id" ]
			);
		}

		for ( var instance in instanceQuery ) {
			var transitionFrom      = "";
			var transitionTo        = "";
			var instanceTransitions = _getStepTransitions( instanceId=instance.id, isArchive=arguments.isHistorical );

			for ( var transition in instanceTransitions ) {
				if ( transition.action == "start" ) {
					transitionTo = transition.to;
				} else if ( transition.action == "next" ) {
					transitionFrom = transitionTo;
					transitionTo   = transition.to;
				} else {
					transitionFrom = transitionTo;
					transitionTo   = "";
				}

				if ( Len( transitionFrom ) && Len( transitionTo ) ) {
					transitionsMap[ "#transitionFrom#|#transitionTo#" ] = transitionsMap[ "#transitionFrom#|#transitionTo#" ] ?: 0;
					transitionsMap[ "#transitionFrom#|#transitionTo#" ] += 1;
				}
			}
		}

		var baseI18nUri     = "webflow.#arguments.webflowId#:step.";
		var stepBaseI18nUri = "webflow.step.";

		for ( var key in transitionsMap ) {
			var fromKey   = ListFirst( key, "|" );
			var fromLabel = stepLabels[ fromKey ] ?: fromKey;
			var toKey     = ListLast(  key, "|" );
			var toLabel   = stepLabels[ toKey ] ?: toKey;

			pointLabels[ fromLabel ] = pointLabels[ fromLabel ] ?: "#fromLabel# (#transitionsMap[ key ]#)";
			pointLabels[ toLabel ]   = pointLabels[ toLabel]    ?: "#toLabel# (#transitionsMap[ key ]#)";

			ArrayAppend( transitions, {
				  from = fromLabel
				, to   = toLabel
				, flow = transitionsMap[ key ]
			} );
		}

		return {
			  transitions = transitions
			, labels      = pointLabels
		};
	}

	public struct function prepareInstanceRuleFilter(
		  required string  type
		, required string  webflowId
		,          string  webflowStep = ""
		,          string  instanceRef = ""
		,          boolean hasValue    = true
		,          struct  timeStruct  = {}
		,          string  userField   = "website_user.id"
	) {
		var exists            = arguments.hasValue ? "exists" : "not exists";
		var forArchived       = !ArrayFind( [ "active", "activetimedout" ], arguments.type );
		var targetObject      = forArchived ? "cfflow_workflow_archived_instance" : "cfflow_workflow_instance";
		var lastModifiedField = forArchived ? "date_archived" : $getPresideObject( targetObject ).getDateModifiedField();

		var extraFilters = [];
		var params       = {};
		var paramSuffix  = CreateUUId().lCase().replace( "-", "", "all" );

		ArrayAppend( extraFilters, {
			  filter       = "#targetObject#.reference = :webflowId#paramSuffix#"
			, filterParams = { "webflowId#paramSuffix#"={ type="cf_sql_varchar", value=arguments.webflowId } }
		} );

		if ( forArchived ) {
			ArrayAppend( extraFilters, {
				  filter       = "cfflow_workflow_archived_instance.archive_reason = :archiveReason#paramSuffix#"
				, filterParams = { "archiveReason#paramSuffix#"={ type="cf_sql_varchar", value=arguments.type } }
			} );
		} else {
			var timeoutOperator = arguments.type == "active" ? ">=" : "<";
			var webflowConfig   = $getPresideObject( "webflow_configuration" ).selectData(
				  filter       = { webflow_id=arguments.webflowId }
				, selectFields = [ "timeout_in_minutes" ]
			);

			ArrayAppend( extraFilters, {
				  filter       = "#targetObject#.datemodified #timeoutOperator# :datemodified#paramSuffix#"
				, filterParams = { "datemodified#paramSuffix#" ={ type="cf_sql_timestamp", value=DateAdd( "n", -1 * Val( webflowConfig?.timeout_in_minutes ), Now() ) } }
			} );
		}

		if ( Len( arguments.instanceRef ) ) {
			ArrayAppend( extraFilters, {
				  filter       = "#targetObject#.sub_reference = :instanceRef#paramSuffix#"
				, filterParams = { "instanceRef#paramSuffix#"={ type="cf_sql_varchar", value=arguments.instanceRef } }
			} );
		}

		if ( Len( arguments.webflowStep ) ) {
			if ( forArchived ) {
				ArrayAppend( extraFilters, {
					  filter       = "cfflow_workflow_archived_instance.active_steps = :stepId#paramSuffix#"
					, filterParams = { "stepId#paramSuffix#"={ type="cf_sql_varchar", value=arguments.webflowStep } }
				} );
			} else {
				ArrayAppend( extraFilters, {
					  having       = "GROUP_CONCAT( DISTINCT instance_histories.result ) LIKE :stepId#paramSuffix#"
					, filterParams = { "stepId#paramSuffix#"={ type="cf_sql_varchar", value="%#arguments.webflowStep#" } }
				} );
			}
		}

		if ( IsDate( arguments.timeStruct.from ?: ""  ) ) {
			ArrayAppend( extraFilters, {
				  filter       = "#targetObject#.#lastModifiedField# >= :datefrom#paramSuffix#"
				, filterParams = { "datefrom#paramSuffix#"={ type="cf_sql_timestamp", value=arguments.timeStruct.from } }
			} );
		}
		if ( IsDate( arguments.timeStruct.to ?: ""  ) ) {
			ArrayAppend( extraFilters, {
				  filter       = "#targetObject#.#lastModifiedField# <= :dateto#paramSuffix#"
				, filterParams = { "dateto#paramSuffix#"={ type="cf_sql_timestamp", value=arguments.timeStruct.to } }
			} );
		}

		var subquery = $getPresideObject( targetObject ).selectData(
			  selectFields        = [ "owner" ]
			, filter              = "#$obfuscateSqlForPreside( '#arguments.userField# = #targetObject#.owner' )# AND #targetObject#.owner IS NOT NULL"
			, extraFilters        = extraFilters
			, forceJoins          = "inner"
			, getSqlAndParamsOnly = true
			, formatSqlParams     = true
		);

		StructAppend( params, subquery.params );

		return {
			  filter       = "#exists# (#$obfuscateSqlForPreside( subquery.sql )#)"
			, filterParams = params
		};
	}

// PRIVATE HELPERS
	private boolean function _sessionsEnabled() {
		var appSettings = getApplicationSettings();

		return !IsBoolean( appSettings.statelessRequest ?: "" ) || !appSettings.statelessRequest;
	}

	private any function _getStepTransitions(
		  required string  instanceId
		,          boolean isArchive = false
	) {
		if ( arguments.isArchive ) {
			return getArchiveInstanceTransitions( archiveInstanceId=arguments.instanceId );
		}

		return $getPresideObject( "cfflow_workflow_instance_history" ).selectData(
			  filter       = { instance=arguments.instanceId }
			, orderBy      = "datecreated"
			, selectFields = [
				  "step AS from"
				, "action"
				, "result AS to"
			]
		);
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
}';
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