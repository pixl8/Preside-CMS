/**
 * Service responsible for the business logic of running ad-hoc tasks
 *
 * @singleton
 * @presideService
 * @autodoc
 *
 */
component displayName="Ad-hoc Task Manager Service" {

// CONSTRUCTOR
	/**
	 * @taskScheduler.inject taskScheduler
	 * @siteService.inject   siteService
	 * @logger.inject        logbox:logger:taskmanager
	 */
	public any function init(
		  required any taskScheduler
		, required any siteService
		, required any logger
	) {
		_setTaskScheduler( arguments.taskScheduler );
		_setSiteService( arguments.siteService );
		_setLogger( arguments.logger );

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Registers a new task, optionally running it there and then
	 * in a background thread
	 *
	 * @autodoc           true
	 * @event             Coldbox event that will be run
	 * @args              Args struct to pass to the coldbox event
	 * @adminOwner        Optional admin user ID, owner of the task
	 * @adminOwner        Optional admin user ID, owner of the task
	 * @webOwner          Optional website user ID, owner of the task
	 * @discardOnComplete Whether or not to discard the task once completed or permanently failed.
	 * @retryInterval     Definition of retry attempts for tasks that fail to run. Array of structs with the following keys, "tries": number of attempts, "interval":number in minutes between tries. For example: `[ { tries:3, interval=5 }, { tries:2, interval=60 }]` will retry three times with 5 minutes between attempts and then retry a further two times with 60 minutes between attempts.
	 */
	public string function createTask(
		  required string  event
		,          struct  args              = {}
		,          string  adminOwner        = ""
		,          string  webOwner          = ""
		,          boolean runNow            = false
		,          boolean discardOnComplete = false
		,          array   retryInterval     = []
	) {
		var taskId = $getPresideObject( "taskmanager_adhoc_task" ).insertData( {
			  event               = arguments.event
			, event_args          = SerializeJson( arguments.args )
			, admin_owner         = arguments.adminOwner
			, web_owner           = arguments.webOwner
			, discard_on_complete = arguments.discardOnComplete
			, retry_interval      = SerializeJson( arguments.retryInterval )
		} );

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
			var task  = getTask( arguments.taskId );
			var event = task.event ?: "";
			var args  = IsJson( task.event_args ?: "" ) ? DeserializeJson( task.event_args ) : {};
			var e     = "";

			if ( task.status == "running" ) {
				$raiseError( error={
					  type    = "AdHoTaskManagerService.task.already.running"
					, message = "Task not run. The task with ID, [#arguments.taskId#], is already running."
				} );

				return false;
			}

			$getPresideObject( "taskmanager_adhoc_task" ).updateData(
				  id   = arguments.taskId
				, data = { status="running" }
			);

			try {
				$getColdbox().runEvent(
					  event          = task.event
					, eventArguments = { args=args, logger=_getTaskLogger( taskId ), progress=_getTaskProgressReporter( taskId ) }
					, private        = true
					, prepostExempt  = true
				);
			} catch( any e ) {
				failTask( taskId=arguments.taskId, error=e );
				$raiseError( error=e );
				return false;
			}

			completeTask( taskId=arguments.taskId );
		}

		return true;
	}

	/**
	 * Runs the task in a background thread
	 *
	 * @autodoc true
	 * @taskId  ID of the task to run
	 */
	public void function runTaskInThread( required string taskId ) {
		if ( _inThread() ) {
			runTask( arguments.taskId );
		}

		thread action="run" name="runTask-#CreateUUId()#" taskId=arguments.taskId {
			runTask( taskId=attributes.taskId );
		}
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

		$getPresideObject( "taskmanager_adhoc_task" ).updateData(
			  id   = arguments.taskId
			, data = { status="succeeded" }
		);
	}

	/**
	 * Marks a task as failed
	 *
	 * @autodoc true
	 * @taskId  ID of the task to mark as failed
	 * @error   Error that prompted task failure
	 */
	public void function failTask( required string taskId, struct error={} ) {
		var nextAttempt = getNextAttemptInfo( arguments.taskId );

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
		var scheduleSettings = $getPresideCategorySettings( category="taskmanager" );

		_getTaskScheduler().createTask(
			  task          = "PresideAdHocTask-" & arguments.taskId
			, url           = getTaskRunnerUrl( taskId=taskId, siteContext=scheduleSettings.site_context )
			, port          = Val( scheduleSettings.http_port ?: "" ) ? scheduleSettings.http_port : 80
			, username      = scheduleSettings.http_username  ?: ""
			, password      = scheduleSettings.http_password  ?: ""
			, proxyServer   = scheduleSettings.proxy_server   ?: ""
			, proxyPort     = scheduleSettings.proxy_port     ?: ""
			, proxyUser     = scheduleSettings.proxy_user     ?: ""
			, proxyPassword = scheduleSettings.proxy_password ?: ""
			, startdate     = DateFormat( arguments.nextAttemptDate, "yyyy-mm-dd" )
			, startTime     = TimeFormat( arguments.nextAttemptDate, "HH:mm:ss" )
			, interval      = "Once"
			, hidden        = true
			, autoDelete    = true
		);

		$getPresideObject( "taskmanager_adhoc_task" ).updateData(
			  id   = arguments.taskId
			, data = {
				  status            = "requeued"
				, last_error        = SerializeJson( arguments.error )
				, attempt_count     = arguments.attemptCount
				, next_attempt_date = arguments.nextAttemptDate
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
	 * Returns progress of the given task as a struct. Struct keys:
	 * [id, progress, status, result].
	 *
	 * @autodoc true
	 * @taskId  ID of the task whose progress you wish to get
	 */
	public struct function getProgress( required string taskId ) {
		var task = getTask( arguments.taskId );

		for( var t in task ) {
			return {
				  id       = t.id
				, status   = t.status
				, progress = t.progress_percentage
				, log      = t.log
				, result   = IsJson( t.result ?: "" ) ? DeserializeJson( t.result ) : {}
			};
		}

		return {};
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
	 * Returns a struct with information about the next retry attempt for a task.
	 * Keys are: "nextAttemptDate", "totalAttempts". Returns an empty struct
	 * if task cannot be retried.
	 *
	 * @autodoc true
	 * @taskId  ID of the task
	 *
	 */
	public struct function getNextAttemptInfo( required string taskId ) {
		var task          = getTask( arguments.taskId );
		var retryConfig   = IsJson( task.retry_interval ?: "" ) ? DeserializeJson( task.retry_interval ) : [];
		var maxAttempts   = 0;
		var nextInterval  = 0;
		var totalAttempts = Val( task.attempt_count ) + 1;
		var info          = {
			  totalAttempts   = totalAttempts
			, nextAttemptDate = ""
		};

		for( var interval in retryConfig ) {
			maxAttempts += Val( interval.tries ?: "" );

			if ( maxAttempts > totalAttempts ) {
				info.nextAttemptDate = DateTimeFormat( DateAdd( "n", Val( interval.interval ?: "" ), Now() ), "yyyy-mm-dd HH:nn" );
				break;
			}
		}

		return info;
	}

	public string function getTaskRunnerUrl( required string taskId, required string siteContext ) {
		var siteSvc    = _getSiteService();
		var site       = siteSvc.getSite( Len( Trim( arguments.siteContext ) ) ? arguments.siteContext : siteSvc.getActiveSiteId() );
		var serverName = ( site.domain ?: cgi.server_name );

		return "http://" & serverName & "/taskmanager/runadhoctask/?taskId=" & arguments.taskId;
	}

// PRIVATE HELPERS
	private any function _getTaskLogger( required string taskId ) {
		return new TaskManagerLoggerWrapper(
			  logboxLogger   = _getLogger()
			, taskRunId      = arguments.taskId
			, taskHistoryDao = $getPresideObject( "taskmanager_adhoc_task" )
		);
	}

	private any function _getTaskProgressReporter( required string taskId ) {
		return new AdHocTaskProgressReporter(
			  adhocTaskManagerService = this
			, taskId                  = arguments.taskId
		);
	}

	private boolean function _inThread() {
		var engine = "ADOBE";

		if ( server.coldfusion.productname == "Railo" ){ engine = "RAILO"; }
		if ( server.coldfusion.productname == "Lucee" ){ engine = "LUCEE"; }

		switch( engine ){
			case "ADOBE"	: {
				if( findNoCase( "cfthread", createObject( "java", "java.lang.Thread" ).currentThread().getThreadGroup().getName() ) ){
					return true;
				}
				break;
			}
			case "RAILO" : case "LUCEE" : {
				return getPageContext().hasFamily();
				break;
			}
		}

		return false;
	}

// GETTERS AND SETTERS
	private any function _getTaskScheduler() {
		return _taskScheduler;
	}
	private void function _setTaskScheduler( required any taskScheduler ) {
		_taskScheduler = arguments.taskScheduler;
	}

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

}