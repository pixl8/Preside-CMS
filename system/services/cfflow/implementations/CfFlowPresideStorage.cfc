/**
 * @feature        cfflow
 * @presideService true
 * @singleton      true
 */
component implements="preside.system.modules.cfflow.models.implementation.interfaces.IWorkflowInstanceStorage" {

// CONSTRUCTOR
	/**
	 * @instanceDao.inject         presidecms:object:cfflow_workflow_instance
	 * @stepStatusDao.inject       presidecms:object:cfflow_workflow_instance_step
	 * @historyDao.inject          presidecms:object:cfflow_workflow_instance_history
	 * @transitionDao.inject       presidecms:object:cfflow_workflow_instance_history_transition
	 * @archivedInstanceDao.inject presidecms:object:cfflow_workflow_archived_instance
	 *
	 */
	public any function init(
		  required any instanceDao
		, required any stepStatusDao
		, required any historyDao
		, required any transitionDao
		, required any archivedInstanceDao
	) {
		_setInstanceDao( arguments.instanceDao );
		_setStepStatusDao( arguments.stepStatusDao );
		_setHistoryDao( arguments.historyDao );
		_setTransitionDao( arguments.transitionDao );
		_setArchivedInstanceDao( arguments.archivedInstanceDao );

		return this;
	}

// PUBLIC API METHODS
	public boolean function instanceExists( required string workflowId, required struct instanceArgs ){
		if ( _isLazyLoad( arguments.instanceArgs ) ) {
			return true;
		}

		var archived = _isArchived( arguments.instanceArgs );
		if ( archived ) {
			return _getArchivedInstanceDao().dataExists( filter=_getInstanceFilter( argumentCollection=arguments ) );
		}
		return _getInstanceDao().dataExists( filter=_getInstanceFilter( argumentCollection=arguments ) );
	}

	public void function createInstance( required string workflowId, required struct instanceArgs ) {
		if ( _isLazyLoad( arguments.instanceArgs ) ) {
			return;
		}

		_getInstanceDao().insertData( data={
			  workflow_id       = arguments.workflowId
			, owner             = arguments.instanceArgs.owner           ?: ""
			, reference         = arguments.instanceArgs.reference       ?: ""
			, sub_reference     = arguments.instanceArgs.subReference    ?: ""
			, sub_sub_reference = arguments.instanceArgs.subSubReference ?: ""
		} );
	}

	public struct function getState( required string workflowId, required struct instanceArgs ) {
		if ( _isLazyLoad( arguments.instanceArgs ) ) {
			return arguments.instanceArgs.lazyLoadedState ?: {};
		}

		var instanceRecord = _getInstance( argumentCollection=arguments );

		if ( Len( Trim( instanceRecord.state ?: "" ) ) ) {
			try {
				var state = DeserializeJson( instanceRecord.state );
				if ( IsStruct( state ) ) {
					return state;
				}
			} catch( any e ) {
				$raiseError( e );
			}
		}

		return {};
	}

	public void function setState( required string workflowId, required struct instanceArgs, required struct state ){
		if ( _isLazyLoad( arguments.instanceArgs ) ) {
			arguments.instanceArgs.lazyLoadedState = arguments.state;
		}

		_getInstanceDao().updateData(
			  filter = _getInstanceFilter( argumentCollection=arguments )
			, data   = { state=SerializeJson( arguments.state ) }
		);
	}

	public void function appendState( required string workflowId, required struct instanceArgs, required struct state ){
		var newState = getState( argumentCollection=arguments );

		StructAppend( newState, arguments.state );

		setState( argumentCollection=arguments, state=newState );
	}

	public string function getStepStatus( required string workflowId, required struct instanceArgs, required string step ) {
		if ( _isLazyLoad( arguments.instanceArgs ) ) {
			arguments.instanceArgs.lazyLoadedStepStatus[ arguments.step ] ?: "";
		}

		if ( _isArchived( arguments.instanceArgs ) ){
			return _getArchivedStepStatus( argumentCollection=arguments );
		}

		var statusRecord = _getStepStatusDao().selectData( filter=_getStepFilter( argumentCollection=arguments ) );

		return statusRecord.status ?: "";
	}
	public void function setStepStatus( required string workflowId, required struct instanceArgs, required string step, required string status ){
		if ( _isLazyLoad( arguments.instanceArgs ) ) {
			arguments.instanceArgs.lazyLoadedStepStatus = arguments.instanceArgs.lazyLoadedStepStatus ?: {};
			arguments.instanceArgs.lazyLoadedStepStatus[ arguments.step ] = arguments.status;

			return;
		}

		var updated = _getStepStatusDao().updateData(
			  filter = _getStepFilter( argumentCollection=arguments )
			, data   = { status=arguments.status }
		);

		if ( !updated ) {
			var instance = _getInstance( argumentCollection=arguments );
			if ( instance.recordCount ) {
				_getStepStatusDao().insertData( data={
					  instance = instance.id
					, step     = arguments.step
					, status   = arguments.status
				} );
			}
		}
	}
	public struct function getAllStepStatuses( required string workflowId, required struct instanceArgs ){
		if ( _isLazyLoad( arguments.instanceArgs ) ) {
			return arguments.instanceArgs.lazyLoadedStepStatus ?: {};
		}
		if ( _isArchived( arguments.instanceArgs ) ){
			return _getArchivedAllStepStatuses( argumentCollection=arguments );
		}

		var records = _getStepStatusDao().selectData( filter=_getStepFilter( argumentCollection=arguments ), orderBy="datecreated" );
		var statuses = StructNew( "linked" );

		for( var step in records ) {
			statuses[ step.step ] = step.status;
		}

		return statuses;
	}
	public void function setComplete( required string workflowId, required struct instanceArgs ) {
		_getInstanceDao().updateData(
			  filter = _getInstanceFilter( argumentCollection=arguments )
			, data   = { completed=true }
		);
	}

	public void function recordAction(
		  required string workflowId
		, required struct instanceArgs
		, required struct state
		, required string actionId
		, required string resultId
		, required array  transitions
		,          string stepId
	) {
		var instance = _getInstance( argumentCollection=arguments );
		if ( instance.recordCount ) {
			var adminUserId = $getAdminLoggedInUserId();
			var historyId = _getHistoryDao().insertData( data={
				  instance                  = instance.id
				, action                    = arguments.actionId
				, step                      = arguments.stepId ?: ""
				, result                    = arguments.resultId
				, state                     = SerializeJson( arguments.state )
				, triggered_by_admin_user   = adminUserId
				, triggered_by_website_user = $isFeatureEnabled( "websiteUsers" ) && !Len( adminUserId ) ? $getWebsiteLoggedInUserId() : ""
			} );

			for( var transition in arguments.transitions ) {
				_getTransitionDao().insertData( data={
					  history = historyId
					, step    = transition.getStep()
					, status  = transition.getNewStatus()
					, old_status = transition.getOldStatus()
				} );
			}
		}
	}

	public string function archiveInstance( required string workflowId, required struct instanceArgs, required string archiveReason ) {
		var currentInstance = _getInstance( argumentCollection=arguments );

		for( var i in currentInstance ){
			var archivedInstance = i;
			var stepStatuses     = getAllStepStatuses( argumentCollection=arguments );
			var transitions      = _getHistoryDao().selectData( filter={ instance=currentInstance.id }, orderby="datecreated" );
			var transitionHist   = [];
			var activeSteps      = [];
			var completedSteps   = [];

			for( var step in stepStatuses ) {
				if ( stepStatuses[ step ] == "complete" ) {
					ArrayAppend( completedSteps, step );
				} else if ( stepStatuses[ step ] == "active" ) {
					ArrayAppend( activeSteps, step );
				}
			}
			for( var transition in transitions ) {
				ArrayAppend( transitionHist, {
					  action = transition.action ?: ""
					, result = transition.result ?: ""
				} );
			}

			activeSteps    = ArrayToList( activeSteps );
			completedSteps = ArrayToList( completedSteps );
			transitionHist = SerializeJson( transitionHist );

			StructAppend( archivedInstance, {
				  time_taken            = DateDiff( "s", archivedInstance.datecreated, archivedInstance.datemodified )
				, date_started          = archivedInstance.datecreated
				, date_archived         = Now()
				, archive_reason        = arguments.archiveReason
				, transition_count      = transitions.recordCount
				, active_steps          = activeSteps
				, completed_steps       = completedSteps
				, step_transitions      = transitionHist
				, completed_steps_hash  = Hash( completedSteps )
				, step_transitions_hash = Hash( transitionHist )
			} );
			StructDelete( archivedInstance, "datecreated" );
			StructDelete( archivedInstance, "datemodified" );

			var archiveId = _getArchivedInstanceDao().insertData( archivedInstance );
			_getInstanceDao().deleteData( id=currentInstance.id );

			return archiveId;
		}

		return "";
	}

	public numeric function deleteInstance( required string workflowId, required struct instanceArgs ) {
		return _getInstanceDao().deleteData( filter=_getInstanceFilter( argumentCollection=arguments ) );
	}

	public any function getLastModified( required string workflowId, required struct instanceArgs ) {
		var instanceRecord = _getInstance( argumentCollection=arguments );

		return instanceRecord.datemodified ?: NullValue();
	}

	public void function transferOwner( required string previousOwner, required string newOwner ) {
		var instanceDao = _getInstanceDao();
		var flows       = instanceDao.selectData(
			  selectFields = [ "id", "workflow_id", "reference", "sub_reference", "sub_sub_reference" ]
			, filter       = { owner=arguments.previousOwner }
		);

		for( var flow in flows ) {
			var hasExistingInstance = instanceDao.dataExists( filter={
				  workflow_id       = flow.workflow_id
				, reference         = flow.reference
				, sub_reference     = flow.sub_reference
				, sub_sub_reference = flow.sub_sub_reference
				, owner             = arguments.newOwner
				, completed         = false
			} );

			if ( hasExistingInstance ) {
				archiveInstance(
					  workflowId    = flow.workflow_id
					, instanceArgs  = {
						  owner           = arguments.previousOwner
						, reference       = flow.reference
						, subReference    = flow.sub_reference
						, subSubReference = flow.sub_sub_reference
					  }
					, archiveReason = "userloggedin"
				);
			} else {
				instanceDao.updateData(
					  id   = flow.id
					, data = { owner=arguments.newOwner }
				);
			}
		}
	}

// PRIVATE HELPERS
	private any function _getInstance( required string workflowId, required struct instanceArgs ) {
		var archived = _isArchived( arguments.instanceArgs );
		if ( archived ) {
			return _getArchivedInstanceDao().selectData( filter=_getInstanceFilter( argumentCollection=arguments ) );
		}
		return _getInstanceDao().selectData( filter=_getInstanceFilter( argumentCollection=arguments ) );
	}

	private struct function _getInstanceFilter( required string workflowId, required struct instanceArgs ) {
		var filter = {
			  workflow_id       = arguments.workflowId
			, owner             = arguments.instanceArgs.owner           ?: ""
			, reference         = arguments.instanceArgs.reference       ?: ""
			, sub_reference     = arguments.instanceArgs.subReference    ?: ""
			, sub_sub_reference = arguments.instanceArgs.subSubReference ?: ""
		};

		if ( Len( arguments.instanceArgs.archiveId ?: "" ) ) {
			filter.id = arguments.instanceArgs.archiveId;
		}

		return filter;
	}

	private struct function _getStepFilter( required string workflowId, required struct instanceArgs, string step="" ) {
		var filter = {
			  "instance.workflow_id"       = arguments.workflowId
			, "instance.owner"             = arguments.instanceArgs.owner           ?: ""
			, "instance.reference"         = arguments.instanceArgs.reference       ?: ""
			, "instance.sub_reference"     = arguments.instanceArgs.subreference    ?: ""
			, "instance.sub_sub_reference" = arguments.instanceArgs.subSubReference ?: ""
		};

		if ( Len( Trim( arguments.step ) ) ){
			filter.step = arguments.step;
		}

		return filter;
	}

	private boolean function _isArchived( required struct instanceArgs ) {
		return Len( arguments.instanceArgs.archiveId ?: "" );
	}

	private boolean function _isLazyLoad( required struct instanceArgs ) {
		return IsBoolean( arguments.instanceArgs.lazyLoad ?: "" ) && arguments.instanceArgs.lazyLoad;
	}

	private string function _getArchivedStepStatus( required string workflowId, required struct instanceArgs, required string step ) {
		var instance = _getInstance( argumentCollection=arguments );

		if ( ListFindNoCase( instance.active_steps ?: "", arguments.step ) ) {
			return "active";
		}
		if ( ListFindNoCase( instance.completed_steps ?: "", arguments.step ) ) {
			return "complete";
		}

		return "pending";
	}

	private struct function _getArchivedAllStepStatuses(  required string workflowId, required struct instanceArgs ) {
		var steps = {};
		var instance = _getInstance( argumentCollection=arguments );

		for( var activeStep in ListToArray( instance.active_steps ?: "" ) ) {
			steps[ activeStep ] = "active";
		}
		for( var completeStep in ListToArray( instance.completed_steps ?: "" ) ) {
			steps[ completeStep ] = "complete";
		}

		return steps;
	}

// GETTERS AND SETTERS
	private any function _getInstanceDao() {
	    return _instanceDao;
	}
	private void function _setInstanceDao( required any instanceDao ) {
	    _instanceDao = arguments.instanceDao;
	}

	private any function _getStepStatusDao() {
	    return _stepStatusDao;
	}
	private void function _setStepStatusDao( required any stepStatusDao ) {
	    _stepStatusDao = arguments.stepStatusDao;
	}

	private any function _getHistoryDao() {
	    return _historyDao;
	}
	private void function _setHistoryDao( required any historyDao ) {
	    _historyDao = arguments.historyDao;
	}

	private any function _getTransitionDao() {
	    return _transitionDao;
	}
	private void function _setTransitionDao( required any transitionDao ) {
	    _transitionDao = arguments.transitionDao;
	}

	private any function _getArchivedInstanceDao() {
	    return _archivedInstanceDao;
	}
	private void function _setArchivedInstanceDao( required any archivedInstanceDao ) {
	    _archivedInstanceDao = arguments.archivedInstanceDao;
	}

}