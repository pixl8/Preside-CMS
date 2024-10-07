/**
 * Service responsible for the business logic of running ad-hoc tasks
 *
 * @singleton      true
 * @presideService true
 * @autodoc        true
 * @feature        adhocTasks
 *
 */
component displayName="Ad-hoc Task Manager Service" {

// CONSTRUCTOR
	/**
	 * @siteService.inject       featureInjector:sites:siteService
	 * @threadUtil.inject        threadUtil
	 * @logger.inject            logbox:logger:adhocTaskManager
 	 * @executor.inject          presideAdhocTaskManagerExecutor
 	 * @staleTaskSettings.inject coldbox:setting:heartbeats.adhocTask.staleTaskSettings
	 */
	public any function init(
		  required any siteService
		, required any logger
		, required any threadUtil
		, required any executor
		, required any staleTaskSettings
	) {
		_setSiteService( arguments.siteService );
		_setLogger( arguments.logger );
		_setThreadUtil( arguments.threadUtil );
		_setExecutor( arguments.executor );

		_setMinStaleLockTimeInMinutes(       arguments.staleTaskSettings.lockedMinAgeInMinutes          ?: 5               );
		_setMaxStaleLockTimeInMinutes(       arguments.staleTaskSettings.lockedMaxAgeInMinutes          ?: ( 7 * 24 * 60 ) );
		_setMinInactiveRunningTimeInMinutes( arguments.staleTaskSettings.inactiveRunningMinAgeInMinutes ?: 240             );
		_setMaxInactiveRunningTimeInMinutes( arguments.staleTaskSettings.inactiveRunningMaxAgeInMinutes ?: ( 7 * 24 * 60 ) );

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Registers a new task, optionally running it there and then
	 * in a background thread
	 *
	 * @autodoc              true
	 * @event                Coldbox event that will be run
	 * @args                 Args struct to pass to the coldbox event
	 * @adminOwner           Optional admin user ID, owner of the task
	 * @adminOwner           Optional admin user ID, owner of the task
	 * @webOwner             Optional website user ID, owner of the task
	 * @runNow               Whether or not to immediately run the task in a background thread. **Note:** If neither `runNow` or `runIn` is set, you will be responsible for running the task yourself with [[adhoctaskmanagerservice-runtask]].
	 * @runIn                Optional *timespan* (`CreateTimeSpan()`) to delay the execution of this task (will only be used if `runNow` is `false`). **Note:** If neither `runNow` or `runIn` is set, you will be responsible for running the task yourself with [[adhoctaskmanagerservice-runtask]].
	 * @discardOnComplete    Whether or not to discard the task once completed or permanently failed. Defaults to `false`
	 * @discardAfterInterval Interval from completion after which the task will be deleted. Defaults to 1 day. Only used when `discardOnComplete` is set to `false` (default).
	 * @retryInterval        Definition of retry attempts for tasks that fail to run. Either a single struct, or array of structs with the following keys: `tries`: number of attempts, `interval`:number in seconds between tries (can also use CreateTimeSpan()). For example: `[ { tries:3, interval=CreateTimeSpan( 0, 0, 5, 0 ) }, { tries:2, interval=3600 }]` will retry three times with 5 minutes between attempts and then retry a further two times with 60 minutes between attempts.
	 * @title                Optional title of the task, can be an i18n resource URI for later translation. This will be used in any task progress UIs, etc.
	 * @titleData            Optional array of strings that will be passed into translateResource() along with title URI to create translatable title
	 * @resultUrl            Optional URL at which the result of this task can be viewed / downloaded. The token, `{taskId}`, within the URL will be replaced with the actual ID of the task
	 * @returnUrl            Optional URL to which to direct users from core admin UIs when they have finished with viewing a task
	 * @reference            Optional string with which to provide a key reference for your task
	 * @disableCancel        Optional disable cancellation of the task
	 */
	public string function createTask(
		  required string   event
		,          struct   args                 = {}
		,          string   adminOwner           = ""
		,          string   webOwner             = ""
		,          boolean  runNow               = false
		,          timespan runIn                = CreateTimeSpan( 0, 0, 0, 0 )
		,          boolean  discardOnComplete    = false
		,          any      discardAfterInterval = CreateTimeSpan( 1, 0, 0, 0 )
		,          any      retryInterval        = []
		,          string   title                = ""
		,          array    titleData            = []
		,          string   resultUrl            = ""
		,          string   returnUrl            = ""
		,          string   reference            = ""
		,          boolean  disableCancel        = false
	) {
		var nextAttemptDate = "";

		if ( arguments.runNow ) {
			var delayInCaseFailsToStart = 30;
			nextAttemptDate = DateAdd( "s", delayInCaseFailsToStart, _now() );
		} else if ( arguments.runIn ) {
			nextAttemptDate = DateAdd( "s", _timespanToSeconds( arguments.runIn ), _now() );
		}

		var taskId = $getPresideObject( "taskmanager_adhoc_task" ).insertData( {
			  event                  = arguments.event
			, event_args             = SerializeJson( _addRequestStateArgs( arguments.args ) )
			, admin_owner            = arguments.adminOwner
			, web_owner              = arguments.webOwner
			, discard_on_complete    = arguments.discardOnComplete
			, discard_after_interval = _isTimespan( arguments.discardAfterInterval ?: "" ) ? _timespanToSeconds( arguments.discardAfterInterval ) : arguments.discardAfterInterval
			, next_attempt_date      = nextAttemptDate
			, retry_interval         = _serializeRetryInterval( arguments.retryInterval )
			, title                  = arguments.title
			, title_data             = SerializeJson( arguments.titleData )
			, result_url             = arguments.resultUrl
			, return_url             = arguments.returnUrl
			, reference              = arguments.reference
			, disable_cancel         = arguments.disableCancel
		} );

		if ( arguments.resultUrl.findNoCase( "{taskId}" ) ) {
			setResultUrl( taskId=taskId, resultUrl=arguments.resultUrl.replaceNoCase( "{taskId}", taskId, "all" ) );
		}

		if ( arguments.runNow ) {
			runTaskInThread( taskId=taskId );
		}

		return taskId;
	}

	/**
	 * Runs a registered task
	 *
	 * @autodoc true
	 * @taskId  ID of the task to run
	 */
	public boolean function runTask( required string taskId ) {
		lock timeout="1" name="adhocRunTask#arguments.taskId#" {
			$getRequestContext().setUseQueryCache( false );
			$getRequestContext().isBackgroundThread( true );

			var task  = getTask( arguments.taskId );
			var event = task.event ?: "";
			var args  = IsJson( task.event_args ?: "" ) ? DeserializeJson( task.event_args ) : {};
			var e     = "";

			_setRequestState( args.__requestState ?: {} );

			if ( !task.recordCount ) {
				return true;
			}

			if ( task.status == "running" || !markTaskAsRunning( taskId=arguments.taskId ) ) {
				$raiseError( error={
					  type    = "AdHoTaskManagerService.task.already.running"
					, message = "Task not run. The task with ID, [#arguments.taskId#], is already running."
				} );

				return false;
			}

			$getRequestContext().setValue( name="_runningAdhocTaskId", value=arguments.taskId, private=true );

			var logger   = _getTaskLogger( taskId );
			var progress = _getTaskProgressReporter( taskId );
			var success  = true;

			try {
				success = $getColdbox().runEvent(
					  event          = task.event
					, eventArguments = { args=args, logger=logger, progress=progress, task=task }
					, private        = true
					, prepostExempt  = true
				);
			} catch( any e ) {
				failTask( taskId=arguments.taskId, error=e );
				$raiseError( error=e );
				logger.error( "An [#( e.type ?: '' )#] error occurred running task. Error message: [#( e.message ?: '' )#]" );
				return false;
			}

			if ( IsBoolean( local.success ?: "" ) && !local.success ) {
				failTask( taskId=arguments.taskId, error={} );
				return false;
			} else {
				completeTask( taskId=arguments.taskId );
			}

		}

		return true;
	}

	/**
	 * Runs any scheduled tasks
	 *
	 * @autodoc true
	 */
	public void function runScheduledTasks() {
		var nextTask = NullValue();
		do {
			var nextTask = getNextScheduledTaskToRun();

			if ( !IsNull( nextTask ) ) {
				runTaskInThread( nextTask.id );
			}
		} while( !IsNull( nextTask ) );
	}


	/**
	 * Runs the task in a background thread
	 *
	 * @autodoc true
	 * @taskId  ID of the task to run
	 */
	public void function runTaskInThread( required string taskId ) {
		if ( !_getExecutor().isStarted() ) {
			_getExecutor().start();
		}

		_getExecutor().submit( new AdhocTaskManagerRunnable(
			  service = this
			, taskId  = arguments.taskId
		) );
	}

	/**
	 * Gets the database record for the given task ID
	 *
	 * @autodoc true
	 * @taskId  ID of the task to get
	 */
	public query function getTask( required string taskId ) {
		return $getPresideObject( "taskmanager_adhoc_task" ).selectData( id=arguments.taskId );
	}

	/**
	 * Returns tasks next task to run that is in the scheduled queue
	 * @autodoc true
	 */
	public any function getNextScheduledTaskToRun() {
		var schedulerLock  = CreateUUId();
		var dao            = $getPresideObject( "taskmanager_adhoc_task" );
		var validStatuses  = [ "pending", "requeued" ];
		var potentialTask  = dao.selectData(
			  selectFields = [ "id " ]
			, filter       = "next_attempt_date < :next_attempt_date and status in (:status)"
			, filterparams = { next_attempt_date=Now(), status=validStatuses }
			, maxRows      = 1
			, orderBy      = "attempt_count,datecreated"
			, useCache     = false
		);

		if ( potentialTask.recordCount ) {
			var statusUpdated = dao.updateData(
				  filter = { id=potentialTask.id, status=validStatuses }
				, data = { status="locked" }
			);
			var otherProcessHasPickedItUp = !statusUpdated;

			if ( otherProcessHasPickedItUp ) {
				return getNextScheduledTaskToRun();
			}

			return potentialTask;
		}

		return;
	}

	/**
	 * Marks a task as running and resets running date, log, stats, etc.
	 *
	 * @autodoc true
	 * @taskId  ID of the task to mark as running
	 */
	public boolean function markTaskAsRunning( required string taskId ) {
		return $getPresideObject( "taskmanager_adhoc_task" ).updateData(
			  filter       = "id = :id and status != :status"
			, filterParams = { id=arguments.taskId, status="running"}
			, data         = {
				  status              = "running"
				, started_on          = _now()
				, progress_percentage = 0
				, log                 = ""
				, next_attempt_date   = ""
				, finished_on         = ""
			  }
		);
	}

	/**
	 * Marks a task as complete
	 *
	 * @autodoc true
	 * @taskId ID of the task to mark as complete
	 */
	public void function completeTask( required string taskId ) {
		var task = getTask( arguments.taskId );

		if ( IsBoolean( task.discard_on_complete ?: "" ) && task.discard_on_complete ) {
			discardTask( taskId=arguments.taskId );
			return;
		}

		var updatedTaskData = { status="succeeded", finished_on=_now() };
		if ( Val( task.discard_after_interval ?: "" ) > 0 ) {
			updatedTaskData.discard_expiry = DateAdd( 's', task.discard_after_interval, Now() );
		}

		$getPresideObject( "taskmanager_adhoc_task" ).updateData(
			  id   = arguments.taskId
			, data = updatedTaskData
		);
	}

	/**
	 * Marks a task as failed
	 *
	 * @autodoc    true
	 * @taskId     ID of the task to mark as failed
	 * @error      Error that prompted task failure
	 * @forceRetry If true, will ignore retry config and automatically queue for retry
	 */
	public void function failTask( required string taskId, struct error={}, boolean forceRetry=false ) {
		var nextAttempt = getNextAttemptInfo( arguments.taskId, arguments.forceRetry );

		if ( IsDate( nextAttempt.nextAttemptDate ) ) {
			requeueTask(
				  taskId          = arguments.taskId
				, error           = arguments.error
				, attemptCount    = nextAttempt.totalAttempts
				, nextAttemptDate = nextAttempt.nextAttemptDate
			);

			return;
		}

		$getPresideObject( "taskmanager_adhoc_task" ).updateData(
			  id   = arguments.taskId
			, data = {
				  status        = "failed"
				, last_error    = SerializeJson( arguments.error )
				, attempt_count = nextAttempt.totalAttempts
				, finished_on   = _now()
			  }
		);
	}

	/**
	 * Requeues a task for execution
	 *
	 * @autodoc         true
	 * @taskId          ID of the task to re-queue
	 * @error           Error that prompted requeue (see failtask())
	 * @attemptCount    Number of attempts made so far
	 * @nextAttemptDate Date of next attempt
	 */
	public void function requeueTask(
		  required string  taskId
		, required date    nextAttemptDate
		,          any     error = {}
		,          numeric attemptCount = 1
	) {
		$getPresideObject( "taskmanager_adhoc_task" ).updateData(
			  id   = arguments.taskId
			, data = {
				  status            = "requeued"
				, last_error        = SerializeJson( arguments.error )
				, attempt_count     = arguments.attemptCount
				, next_attempt_date = arguments.nextAttemptDate
				, finished_on       = _now()
			  }
		);

		return;
	}

	/**
	 * Sets progress on a task
	 *
	 * @autodoc  true
	 * @taskId   ID of the task
	 * @progress Progress percentage of the task
	 */
	public void function setProgress( required string taskId, required numeric progress ) {
		$getPresideObject( "taskmanager_adhoc_task" ).updateData(
			  id   = arguments.taskId
			, data = { progress_percentage=arguments.progress }
		);
	}

	/**
	 * Sets the result of a task
	 *
	 * @autodoc  true
	 * @taskId   ID of the task
	 * @result   The task result (will be serialized when saving against DB record)
	 */
	public void function setResult( required string taskId, required any result ) {
		$getPresideObject( "taskmanager_adhoc_task" ).updateData(
			  id   = arguments.taskId
			, data = { result=SerializeJson( arguments.result ) }
		);
	}

	/**
	 * Sets the result URL of a task. Useful/required when wanting
	 * to use built in admin UIs for progress / result viewing of tasks
	 *
	 * @autodoc   true
	 * @taskId    ID of the task
	 * @resultUrl The URL for viewing the result of the task
	 */
	public void function setResultUrl( required string taskId, required any resultUrl ) {
		$getPresideObject( "taskmanager_adhoc_task" ).updateData(
			  id   = arguments.taskId
			, data = { result_url=arguments.resultUrl }
		);
	}

	/**
	 * Returns progress of the given task as a struct. Struct keys:
	 * [id, progress, status, result].
	 *
	 * @autodoc true
	 * @taskId  ID of the task whose progress you wish to get
	 */
	public struct function getProgress( required string taskId ) {
		var task = getTask( arguments.taskId );

		for( var t in task ) {
			var timeTaken     = 0;
			var timeRemaining = 0;

			switch( t.status ) {
				case "running":
					timeTaken = DateDiff( 's', t.started_on, _now() );
					if ( Val( t.progress_percentage ) && t.progress_percentage < 100 ) {
						timeRemaining = Round( ( timeTaken / t.progress_percentage ) * ( 100-t.progress_percentage ) );
					}
				break;
				case "requeued":
				case "succeeded":
				case "failed":
					timeTaken = DateDiff( 's', t.started_on, t.finished_on );
				break;
			}
			return {
				  id            = t.id
				, status        = t.status
				, progress      = t.progress_percentage
				, log           = t.log
				, resultUrl     = t.result_url
				, returnUrl     = t.return_url
				, result        = IsJson( t.result ?: "" ) ? DeserializeJson( t.result ) : {}
				, timeTaken     = timeTaken
				, timeRemaining = timeRemaining
			};
		}

		return {};
	}

	/**
	 * Returns a db query of the individual log lines of the task
	 * [ts, severity, line ].
	 *
	 * @autodoc          true
	 * @taskId           ID of the task whose logs you wish to get
	 * @fetchAfterLines  Only fetch lines after this line number
	 */
	public query function getLogLines( required string taskId, numeric fetchAfterLines=0 ) {
		return $getPresideObject( "taskmanager_adhoc_task_log_line" ).selectData(
			  selectFields = [ "ts", "severity", "line" ]
			, orderby      = "id"
			, maxRows      = arguments.fetchAfterLines ? 1000000 : 0 // impossibly high number. Forcing startRow to work without really wanting a max rows
			, startRow     = arguments.fetchAfterLines + 1
			, filter       = { task=arguments.taskId }
		);
	}

	/**
	 * Returns number of lines in this tasks logs
	 *
	 * @autodoc          true
	 * @taskId           ID of the task whose logs you wish to get
	 */
	public numeric function getLogLineCount( required string taskId ) {
		return $getPresideObject( "taskmanager_adhoc_task_log_line" ).selectData(
			  recordCountOnly = true
			, filter          = { task=arguments.taskId }
		);
	}


	/**
	 * Discards the given task
	 *
	 * @autodoc true
	 * @taskId  ID of the task to discard
	 */
	public boolean function discardTask( required string taskId ) {

		$getPresideObject( "taskmanager_adhoc_task" ).deleteData( id=arguments.taskId );

		return true;
	}

	/**
	 * Cancels a given task
	 *
	 * @autodoc true
	 * @taskId  ID of the task to discard
	 */
	public boolean function cancelTask( required string taskId ) {
		var task = getTask( arguments.taskId );

		if ( IsBoolean( task.disable_cancel ?: "" ) && task.disable_cancel ) {
			return false;
		}

		if ( IsBoolean( task.discard_on_complete ?: "" ) && task.discard_on_complete ) {
			return discardTask( taskId=arguments.taskId );
		}

		var updatedTaskData = { status="cancelled", finished_on=_now() };
		if ( Val( task.discard_after_interval ?: "" ) > 0 ) {
			updatedTaskData.discard_expiry = DateAdd( 's', task.discard_after_interval, Now() );
		}

		return $getPresideObject( "taskmanager_adhoc_task" ).updateData(
			  id   = arguments.taskId
			, data = updatedTaskData
		);
	}

	/**
	 * isActiveTaskCancelled
	 *
	 */
	public boolean function isActiveTaskCancelled() {
		var taskId = $getRequestContext().getValue( name="_runningAdhocTaskId", defaultValue="", private=true );
		if ( !Len( Trim( taskId ) ) ) {
			return false;
		}

		var task = getTask( taskId );
		return !task.recordCount || task.status == "cancelled";
	}

	/**
	 * Returns a struct with information about the next retry attempt for a task.
	 * Keys are: "nextAttemptDate", "totalAttempts". Returns an empty struct
	 * if task cannot be retried.
	 *
	 * @autodoc    true
	 * @taskId     ID of the task
	 * @forceRetry If true, will ignore retry config and automatically queue for retry
	 *
	 */
	public struct function getNextAttemptInfo( required string taskId, boolean forceRetry=false ) {
		var task          = getTask( arguments.taskId );
		var retryConfig   = IsJson( task.retry_interval ?: "" ) ? DeserializeJson( task.retry_interval ) : [];
		var maxAttempts   = 0;
		var nextInterval  = 0;
		var totalAttempts = arguments.forceRetry ? Val( task.attempt_count ) : Val( task.attempt_count ) + 1;
		var info          = {
			  totalAttempts   = totalAttempts
			, nextAttemptDate = ""
		};

		if ( arguments.forceRetry ) {
			info.nextAttemptDate = DateTimeFormat( DateAdd( "n", 1, _now() ), "yyyy-mm-dd HH:nn:ss" );
			return info;
		}

		for( var interval in retryConfig ) {
			maxAttempts += Val( interval.tries ?: "" );

			if ( maxAttempts > totalAttempts ) {
				info.nextAttemptDate = DateTimeFormat( DateAdd( "s", Val( interval.interval ?: "" ), _now() ), "yyyy-mm-dd HH:nn:ss" );
				break;
			}
		}

		return info;
	}

	public string function getTaskRunnerUrl( required string taskId, required string siteContext ) {
		var event                  = $getRequestContext();

		if ( $isFeatureEnabled( "sites" ) ) {
			var currentSite            = event.getSite();
			var isDifferentSiteContext = StructIsEmpty( currentSite ) && Len( Trim( arguments.siteContext ) );

			if ( isDifferentSiteContext ) {
				event.setSite( _getSiteService().getSite( arguments.siteContext ) );
			}
		}

		return event.buildLink( linkto="taskmanager.runAdhocTask", queryString="taskId=" & arguments.taskId );
	}

	public boolean function deleteExpiredAdhocTasks( logger ) {
		var canLog = StructKeyExists( arguments, "logger" );
		var canInfo = canLog && arguments.logger.canInfo();

		if ( canInfo ) {
			arguments.logger.info( "Deleting ad-hoc tasks that have expired..." );
		}

		var tasksDeleted = $getPresideObject( "taskmanager_adhoc_task" ).deleteData(
			  filter       = "discard_expiry is not null and :discard_expiry > discard_expiry"
			, filterParams = { discard_expiry=Now() }
		);

		var daysToKeepLogs   = val( $getPresideSetting( "taskmanager", "keep_logs_for_days", 7 ) );
		var oldestDateToKeep = dateAdd( "d", 0-daysToKeepLogs, Now() );
		var outdatedDeleted  = $getPresideObject( "taskmanager_adhoc_task" ).deleteData(
			  filter       = "finished_on < :finished_on"
			, filterParams = { finished_on=oldestDateToKeep }
		);

		if ( outdatedDeleted ) {
			tasksDeleted += outdatedDeleted;
		}

		if ( canInfo ) {
			if ( tasksDeleted ) {
				arguments.logger.info( "Deleted [#NumberFormat( tasksDeleted )#] expired tasks." );
			} else {
				arguments.logger.info( "There were no expired tasks to delete." );
			}
		}

		return true;
	}

	public void function processStaleLockedTasks() {
		var minAge = DateAdd( "n", 0-_getMinStaleLockTimeInMinutes(), Now() );
		var maxAge = DateAdd( "n", 0-_getMaxStaleLockTimeInMinutes(), Now() );

		$getPresideObject( "taskmanager_adhoc_task" ).updateData(
			  filter       = "status = :status and datemodified < :minAge and datemodified > :maxAge"
			, filterParams = {
				  status = "locked"
				, minAge = { type="cf_sql_datetime", value=minAge }
				, maxAge = { type="cf_sql_datetime", value=maxAge }
			  }
			, data         = {
				  status     = "pending"
				, last_error = '{"message":"Task was stuck in \"locked\" status and has been requeued."}'
			  }
		);

		$getPresideObject( "taskmanager_adhoc_task" ).updateData(
			  filter       = "status = :status and datemodified <= :datemodified"
			, filterParams = { status="locked", dateModified=maxAge }
			, data         = {
				  status        = "failed"
				, last_error    = '{"message":"Task marked as failed as it has been in a locked status for longer than the configured age (#NumberFormat( maxAge )# minutes)" }'
				, finished_on   = _now()
			  }
		);
	}

	public void function failInactiveRunningTasks() {
		var minAge = DateAdd( "n", 0-_getMinInactiveRunningTimeInMinutes(), Now() );
		var maxAge = DateAdd( "n", 0-_getMaxInactiveRunningTimeInMinutes(), Now() );
		var tasks = $getPresideObject( "taskmanager_adhoc_task" ).selectData(
			  selectFields = [ "id" ]
			, filter       = "status = :status and datemodified < :minAge and datemodified > :maxAge"
			, filterParams = {
				  status = "running"
				, minAge = { type="cf_sql_datetime", value=minAge }
				, maxAge = { type="cf_sql_datetime", value=maxAge }
			  }
		);

		for( var task in tasks ) {
			failTask( taskId=task.id, error={ message="Task marked as running but no activity for at least #_getMinInactiveRunningTimeInMinutes()# minutes. Failing task as timed out." } );
		}

		$getPresideObject( "taskmanager_adhoc_task" ).updateData(
			  filter       = "status = :status and datemodified <= :datemodified"
			, filterParams = { status="running", dateModified=maxAge }
			, data         = {
				  status        = "failed"
				, last_error    = '{"message":"Task marked as permanently failed as it has been in a running status for longer than the configured max age (#NumberFormat( maxAge )# minutes)" }'
				, finished_on   = _now()
			  }
		);
	}

// PRIVATE HELPERS
	private any function _getTaskLogger( required string taskId ) {
		return new TaskManagerLoggerWrapper(
			  logboxLogger   = _getLogger()
			, taskRunId      = arguments.taskId
			, taskHistoryDao = $getPresideObject( "taskmanager_adhoc_task_log_line" )
		);
	}

	private any function _getTaskProgressReporter( required string taskId ) {
		return new AdHocTaskProgressReporter(
			  adhocTaskManagerService = this
			, taskId                  = arguments.taskId
		);
	}

	private boolean function _inChildThread() {
		var currentThreadName = CreateObject( "java", "java.lang.Thread" ).currentThread().getThreadGroup().getName();

		return currentThreadName.findNoCase( "cfthread" );
	}

	private date function _now() {
		return Now(); // to help with automated tests
	}

	private string function _serializeRetryInterval( required any retryInterval ) {
		var raw       = IsArray( arguments.retryInterval ) ? Duplicate( arguments.retryInterval ) : [ Duplicate( arguments.retryInterval ) ];
		var converted = [];

		for( var config in raw ) {
			converted.append({
				  tries    = Val( config.tries ?: 1 )
				, interval = _isTimespan( config.interval ?: "" ) ? _timespanToSeconds( config.interval ) : config.interval
			});
		}

		return SerializeJson( converted );
	}

	private boolean function _isTimespan( required any input ) {
		try {
			var inputClass = arguments.input.getClass().getName();

			return FindNoCase( "timespan", inputClass );
		} catch( any e ) {}

		return false;
	}

	private any function _timespanToSeconds( required any input ) {
		var secondsInADay = 86400;

		return Round( Val( arguments.input ) * secondsInADay );
	}

	private void function _setRequestState( required struct requestState ){
		var event = $getRequestContext();

		if ( $isFeatureEnabled( "sites" ) ) {
			if ( Len( Trim( requestState.site ?: "" ) ) ) {
				event.setSite( _getSiteService().getSite( requestState.site ) );
			} else if ( $isFeatureEnabled( "sites" ) ) {
				var siteContext = $getPresideSetting( "taskmanager", "site_context" );

				if ( Len( Trim( siteContext ) ) ) {
					event.setSite( _getSiteService().getSite( siteContext ) );
				} else {
					event.autoSetSiteByHost();
				}
			}
		}

		if ( Len( Trim( requestState.language ?: "" ) ) ) {
			event.setLanguage( requestState.language );
		}
	}

	private struct function _addRequestStateArgs( required struct args ) {
		var event = $getRequestContext();

		args.__requestState = {
			  site     = event.getSiteId()
			, language = event.getLanguage()
		}

		return args;
	}

// GETTERS AND SETTERS
	private any function _getSiteService() {
		return _siteService;
	}
	private void function _setSiteService( required any siteService ) {
		_siteService = arguments.siteService;
	}

	private any function _getLogger() {
		return _logger;
	}
	private void function _setLogger( required any logger ) {
		_logger = arguments.logger;
	}

	private any function _getThreadUtil() {
		return _threadUtil;
	}
	private void function _setThreadUtil( required any threadUtil ) {
		_threadUtil = arguments.threadUtil;
	}

	private any function _getExecutor() {
	    return _executor;
	}
	private void function _setExecutor( required any executor ) {
	    _executor = arguments.executor;
	}

	private any function _getMinStaleLockTimeInMinutes() {
	    return _minStaleLockTimeInMinutes;
	}
	private void function _setMinStaleLockTimeInMinutes( required numeric minStaleLockTimeInMinutes ) {
	    _minStaleLockTimeInMinutes = arguments.minStaleLockTimeInMinutes;
	}

	private any function _getMaxStaleLockTimeInMinutes() {
	    return _maxStaleLockTimeInMinutes;
	}
	private void function _setMaxStaleLockTimeInMinutes( required numeric maxStaleLockTimeInMinutes ) {
	    _maxStaleLockTimeInMinutes = arguments.maxStaleLockTimeInMinutes;
	}

	private any function _getMinInactiveRunningTimeInMinutes() {
	    return _minInactiveRunningTimeInMinutes;
	}
	private void function _setMinInactiveRunningTimeInMinutes( required numeric minInactiveRunningTimeInMinutes ) {
	    _minInactiveRunningTimeInMinutes = arguments.minInactiveRunningTimeInMinutes;
	}

	private any function _getMaxInactiveRunningTimeInMinutes() {
	    return _maxInactiveRunningTimeInMinutes;
	}
	private void function _setMaxInactiveRunningTimeInMinutes( required numeric maxInactiveRunningTimeInMinutes ) {
	    _maxInactiveRunningTimeInMinutes = arguments.maxInactiveRunningTimeInMinutes;
	}



}