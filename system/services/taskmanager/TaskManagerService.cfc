/**
 * Service responsible for the business logic for the Preside Task Manager system.
 *
 * @singleton
 * @presideService
 * @autodoc
 *
 */
component displayName="Task Manager Service" {

// CONSTRUCTOR
	/**
	 * @configWrapper.inject               taskManagerConfigurationWrapper
	 * @controller.inject                  coldbox
	 * @taskDao.inject                     presidecms:object:taskmanager_task
	 * @taskHistoryDao.inject              presidecms:object:taskmanager_task_history
	 * @systemConfigurationService.inject  systemConfigurationService
	 * @logger.inject                      logbox:logger:taskmanager
	 * @errorLogService.inject             errorLogService
	 * @siteService.inject                 siteService
	 * @threadUtil.inject                  threadUtil
	 * @executor.inject                    presideTaskManagerExecutor
	 *
	 */
	public any function init(
		  required any configWrapper
		, required any controller
		, required any taskDao
		, required any taskHistoryDao
		, required any systemConfigurationService
		, required any logger
		, required any errorLogService
		, required any siteService
		, required any threadUtil
		, required any executor
	) {
		_setConfiguredTasks( arguments.configWrapper.getConfiguredTasks() );
		_setController( arguments.controller );
		_setTaskDao( arguments.taskDao );
		_setTaskHistoryDao( arguments.taskHistoryDao );
		_setSystemConfigurationService( arguments.systemConfigurationService );
		_setLogger( arguments.logger );
		_setErrorLogService( arguments.errorLogService );
		_setSiteService( arguments.siteService );
		_setThreadUtil( arguments.threadUtil );
		_setExecutor( arguments.executor );
		_setMachineId();

		_initialiseDb();
		_setRunningTasks({});

		return this;
	}

// PUBLIC API METHODS
	public array function listTasks( string exclusivityGroup="" ) {
		if ( !Len( Trim( arguments.exclusivityGroup ) ) ) {
			return _getConfiguredTasks().keyArray();
		}

		var allTasks = _getConfiguredTasks();
		var filtered = [];

		for( var task in allTasks ) {

			if ( ( allTasks[ task ].exclusivityGroup ?: "" ) == arguments.exclusivityGroup ) {
				filtered.add( task );
			}
		}

		return filtered;

	}

	public struct function getTask( required string taskKey ) {
		var tasks = _getConfiguredTasks();

		return tasks[ arguments.taskKey ] ?: throw( type="TaskManager.missing.task", message="Task [#arguments.taskKey#] does not exist. Existing tasks are: #SerializeJson( listTasks() )#" );
	}

	public struct function getTaskConfiguration( required string taskKey ) {
		var task        = getTask( arguments.taskKey );
		var taskDetails = _getTaskDao().selectData(
			  filter       = { task_key=arguments.taskKey }
			, selectFields = [ "crontab_definition", "enabled" ]
		);

		for( var t in taskDetails ) {
			if ( !Len( Trim( t.crontab_definition ) ) ) {
				t.crontab_definition = task.schedule;
			}

			return t;
		}

		return {};
	}

	public void function saveTaskConfiguration( required string taskKey, required struct config  ) {
		_getTaskDao().updateData(
			  filter = { task_key=arguments.taskKey }
			, data   = arguments.config
		);

		_getTaskDao().updateData(
			  filter = { task_key=arguments.taskKey }
			, data   = { next_run = getNextRunDate( arguments.taskKey ) }
		);
	}

	public string function getValidationErrorMessageForPotentiallyBadCrontabExpression( required string crontabExpression ) {
		try {
			_getCrontabExpressionObject( arguments.cronTabExpression );
		} catch ( any e ) {
			return e.message;
		}

		return "";
	}

	public boolean function taskExists( required string taskKey ) {
		return StructKeyExists( _getConfiguredTasks(), arguments.taskKey );
	}

	public boolean function tasksAreRunning( string exclusivityGroup="" ) {
		for( var taskKey in listTasks( exclusivityGroup=arguments.exclusivityGroup ) ){
			if ( taskIsRunning( taskKey ) ) {
				return true
			}
		}

		return false;
	}

	public boolean function taskIsRunning( required string taskKey ) {
		transaction {
			var markedAsRunning = _getTaskDao().dataExists( filter = { task_key=arguments.taskKey, is_running=true } );

			if ( markedAsRunning && !taskThreadIsRunning( arguments.taskKey ) ) {
				var logger = _getLogger( taskKey=arguments.taskKey );

				if ( logger.canError() ) {
					logger.error( "Task was marked as running but task thread is no longer running." );
				}

				markTaskAsCompleted(
					  taskKey   = arguments.taskKey
					, success   = false
					, timetaken = -1
				);
				return false;
			}

			return markedAsRunning;
		}
	}

	public boolean function taskThreadIsRunning( required string taskKey ) {
		var task = _getTaskDao().selectData(
			  selectFields = [ "running_thread", "running_machine" ]
			, filter       = { task_key=arguments.taskKey }
		);

		if ( !task.recordCount || !Len( Trim( task.running_thread ) ) ) {
			return false;
		}

		if ( task.running_machine != _getMachineId() ) {
			return true;
		}

		return _taskisRunningOnLocalMachine( task );
	}

	public array function getRunnableTasks() {
		var taskConfiguration = _getConfiguredTasks();
		var runnableTasks     = [];
		var groupsToRun       = {};
		var nonRunningTasks   = _getTaskDao().selectData(
			  selectFields = [ "task_key" ]
			, filter       = "enabled = :enabled and is_running = :is_running and next_run < :next_run"
			, filterParams = { enabled = true, is_running = false, next_run = _getOperationDate() }
			, orderBy      = "priority desc"
			, useCache     = false
		);

		for( var task in nonRunningTasks ) {
			var exclusivityGroup = taskConfiguration[ task.task_key ].exclusivityGroup ?: "";

			if ( exclusivityGroup == "none" || ( !StructKeyExists( groupsToRun, exclusivityGroup ) && !tasksAreRunning( exclusivityGroup ) ) ) {
				runnableTasks.append( task.task_key );
				groupsToRun[ exclusivityGroup ] = 1;
			}
		}

		return runnableTasks;
	}

	/**
	 * Runs the specified task. e.g.
	 * \n
	 * ```luceescript
	 * taskmanagerService.runTask(
	 * \t  taskKey = "resizeImages"
	 * \t, args    = { derivative="thumbnail" }
	 * );
	 * ```
	 * \n
	 * See [[taskmanager]] for more detail.
	 *
	 * @autodoc
	 * @taskKey.hint The 'key' of the task (this is the Tasks.cfc handler action name)
	 * @args.hint    An optional struct of variables that will be passed to the task handler action
	 *
	 */
	public void function runTask( required string taskKey, struct args={} ) {
		var lockName = "runtask-#taskKey#" & Hash( ExpandPath( "/" ) );

		lock name=lockName type="exclusive" timeout=1 {
			var newThreadId = "PresideTaskmanagerTask-" & arguments.taskKey & "-" & CreateUUId();
			var newLogId    = createTaskHistoryLog( arguments.taskKey, newThreadId );
			var logger      =  _getLogger( newLogId );

			transaction {
				if ( taskIsRunning( arguments.taskKey ) ) {
					return;
				}

				markTaskAsRunning( arguments.taskKey, newThreadId );
			}

			if ( !_getExecutor().isStarted() ) {
				_getExecutor().start();
			}

			var executor = _getExecutor().submit( new TaskManagerRunnable(
				  service  = this
				, taskKey  = arguments.taskKey
				, args     = arguments.args
				, threadId = newThreadId
				, logger   = logger
			) );

			markTaskAsStarted( newThreadId, executor );
		}
	}

	public void function runTaskWithinThread(
		  required string taskKey
		, required struct args
		, required string threadId
		, required any    logger
	) {
		var task    = getTask( arguments.taskKey );
		var start   = getTickCount();
		var success = false;
		var tu      = _getThreadUtil();

		try {
			$getRequestContext().setUseQueryCache( false );
			_setActiveSite();
			success = _getController().runEvent(
				  event          = task.event
				, private        = true
				, eventArguments = { logger=arguments.logger, args=arguments.args }
			);
		} catch( any e ) {
			if ( e.type contains "interrupt" || e.message contains "intterrupted" || e.detail contains "interrupted" )  {
				success=false;

				if ( logger.canError() ) {
					logger.error( "The task [#task.name#] was prematurely interrupted and has been stopped." );
				}
			} else {
				if ( logger.canError() ) {
					logger.error( "An error occurred running task [#task.name#]. Message: [#e.message#], detail [#e.detail#].", e );
				}

				_getErrorLogService().raiseError( e );

				success = false;
				rethrow;
			}
		} finally {
			try {
				markTaskAsCompleted(
					  taskKey   = arguments.taskKey
					, success   = success
					, timeTaken = GetTickCount() - start
					, threadId  = arguments.threadId
				);
			} catch( any e ) {
				if ( arguments.logger.canError() ) {
					arguments.logger.error( "An error occurred running task [#task.name#]. Message: [#e.message#], detail [#e.detail#].", e );
				}

				_getErrorLogService().raiseError( e );

				rethrow;
			}
		}
	}

	public boolean function killRunningTask( required string taskKey, numeric timeout=1000 ) {
		var task = _getTaskDao().selectData(
			  selectFields = [ "running_thread" ]
			, filter = { task_key=arguments.taskKey }
		);

		if ( task.recordCount && Len( Trim( task.running_thread ) ) ) {
			var logger = _getLogger( taskKey=arguments.taskKey );
			if ( logger.canWarn() ) {
				logger.warn( "Task manually cancelled by user. Killing task thread now..." );
			}
			try {
				var runningTasks = _getRunningTasks();
				var theThread    = runningTasks[ task.running_thread ].thread ?: NullValue();

				if ( !IsNull( theThread ) ) {
					var attempt = 0;
					var maxAttempts = 10;
					var cancelled = false;
					while( ++attempt <= maxAttempts && !cancelled ) {
						if ( attempt > 1 ) {
							$systemOutput( "Waiting to gracefully shutdown thread for [#arguments.taskKey#]." );
							if ( logger.canWarn() ) { logger.warn( "Waiting to gracefully shutdown task." ); }
						}

						cancelled = theThread.cancel( true ) && theThread.isCancelled();
						if ( !cancelled ) {
							sleep( 100 );
						}
					}

					if ( theThread.isCancelled() ) {
						$systemOutput( "Successfully shutdown scheduled task thread for [#arguments.taskKey#]." );
						if ( logger.canWarn() ) { logger.warn( "Successfully shutdown scheduled task thread." ); }
					} else {
						$systemOutput( "Failed to gracefully shutdown scheduled task thread for [#arguments.taskKey#]." );
						if ( logger.canWarn() ) { logger.warn( "Failed to gracefully shutdown scheduled task thread." ); }
					}
				}
			} catch( any e ) {
				if ( logger.canError() ) {
					logger.error( "Task errored while terminating. Error: #e.message#. Detail: #e.detail#." );
				}
			}

			markTaskAsCompleted( taskKey=arguments.taskKey, success=false, timeTaken=0 );
		}

		return !taskIsRunning( taskKey );
	}

	public void function killAllRunningTasks( numeric timeout=0 ) {
		for( var taskKey in listTasks() ){
			if ( taskIsRunning( taskKey ) ) {
				killRunningTask( taskKey, arguments.timeout );
			}
		}
	}

	public void function cleanupNoLongerRunningTasks() {
		var localTaskThreads          = _getRunningTasks();
		var runningTasksAccordingToDb = _getTaskDao().selectData(
			  filter = { is_running=true, running_machine=_getMachineId() }
		);

		for( var task in runningTasksAccordingToDb ) {
			if ( !_taskisRunningOnLocalMachine( task ) ) {
				markTaskAsCompleted(
					  taskKey   = task.task_key
					, success   = false
					, timetaken = -1
				);
			}
		}

		for( var threadId in localTaskThreads ) {
			var markedAsRunningInDb = _getTaskDao().dataExists(
				filter = { running_thread=threadId, is_running=true, running_machine=_getMachineId() }
			);

			if ( !markedAsRunningInDb ) {
				localTaskThreads.delete( threadId, false );
			}
		}


	}

	public array function listTasksStoredInStatusDb() {
		var taskRecords = _getTaskDao().selectData( selectFields=[ "task_key" ] );

		return taskRecords.recordCount ? ValueArray( taskRecords.task_key ) : [];
	}

	public void function ensureTasksExistInStatusDb() {
		var existingTasksInDb = listTasksStoredInStatusDb();
		var configuredTasks   = listTasks();

		for( var task in configuredTasks ){
			if ( !existingTasksInDb.find( task ) ) {
				addTaskToStatusDb( task );
			}
		}

		for( var task in existingTasksInDb ) {
			if ( !configuredTasks.find( task ) ) {
				removeTaskFromStatusDb( task );
			}
		}
	}

	public numeric function markTaskAsRunning( required string taskKey, required string threadId ) {
		var runningTasks = _getRunningTasks();

		runningTasks[ arguments.threadId ] = { status="queued", thread=NullValue() };

		return _getTaskDao().updateData(
			  filter = { task_key = arguments.taskKey }
			, data   = {
				  is_running      = true
				, next_run        = getNextRunDate( arguments.taskKey )
				, running_thread  = arguments.threadId
				, running_machine = _getMachineId()
			  }
		);
	}

	public void function markTaskAsStarted( required string threadId, required any threadRef ) {
		var runningTasks = _getRunningTasks();

		runningTasks[ arguments.threadId ] = { status="started", thread=arguments.threadRef };
	}

	public numeric function markTaskAsCompleted( required string taskKey, required boolean success, required numeric timeTaken ) {
		completeTaskHistoryLog( argumentCollection=arguments );
		var runningTasks = _getRunningTasks();
		var taskRecord   = _getTaskDao().selectData( filter={ task_key=arguments.taskKey } );

		runningTasks.delete( taskRecord.running_thread ?: "", false );

		var updatedRows = _getTaskDao().updateData(
			  filter = { task_key = arguments.taskKey }
			, data   = {
				  is_running           = false
				, last_ran             = _getOperationDate()
				, next_run             = getNextRunDate( arguments.taskKey )
				, was_last_run_success = arguments.success
				, last_run_time_taken  = arguments.timeTaken
				, running_thread       = ""
				, running_machine      = ""
			  }
		);

		return updatedRows;
	}

	public string function createTaskHistoryLog( required string taskKey, required string threadId ) {
		purgeTaskHistoryLog( arguments.taskKey );

		return _getTaskHistoryDao().insertData( data={
			  task_key   = arguments.taskKey
			, thread_id  = arguments.threadId
			, machine_id = _getMachineId()
		} );
	}

	public numeric function completeTaskHistoryLog( required string taskKey, required boolean success, required numeric timeTaken ) {
		var historyId = getActiveHistoryIdForTask( arguments.taskKey );
		if ( Len( Trim( historyId ) ) ) {
			_getTaskHistoryDao().updateData(
				  id = historyId
				, data = { complete=true, success=arguments.success, time_taken=arguments.timeTaken }
			);
		}
	}

	public string function getActiveHistoryIdForTask( required string taskKey ) {
		var task = _getTaskDao().selectData(
			  selectFields = [ "running_thread" ]
			, filter = { task_key=arguments.taskKey }
		);

		if ( Len( Trim( task.running_thread ) ) ) {
			var history = _getTaskHistoryDao().selectData( selectFields=[ "id" ], filter={ thread_id = task.running_thread } );
			if ( history.recordCount ) {
				return history.id;
			}
		}

		return "";
	}

	public numeric function purgeTaskHistoryLog( required string taskKey ) {
		var daysToKeepLogs   = Val( _getSystemConfigurationService().getSetting( "taskmanager", "keep_logs_for_days", 7 ) );
		var oldestDateToKeep = DateAdd( "d", 0-daysToKeepLogs, Now() );

		return _getTaskHistoryDao().deleteData(
			  filter       = "task_key = :task_key and datecreated < :datecreated"
			, filterParams = { task_key = arguments.taskKey, datecreated = oldestDateToKeep }
		);
	}

	public struct function runScheduledTasks() {
		var settings              = _getSystemConfigurationService().getCategorySettings( "taskmanager" );
		var scheduledTasksEnabled = settings.scheduledtasks_enabled ?: false;
		var site_context          = settings.site_context           ?: "";
		var siteSvc               = _getSiteService();
		var activeSite            = siteSvc.getActiveSiteId();

		if ( !Len( Trim( activeSite ) ) ) {
			$getRequestContext().setSite( siteSvc.getSite( site_context ) );
			activeSite = siteSvc.getActiveSiteId();
		}

		if ( !IsBoolean( scheduledTasksEnabled ) || !scheduledTasksEnabled ) {
			return { tasksStarted=[], warning="Scheduled tasks are disabled" };
		}

		if ( Len( Trim( site_context ) ) && site_context != siteSvc.getActiveSiteId() ) {
			return { tasksStarted=[], warning="Scheduled tasks are not configured to run for this site context. Please review your general task manager configuration settings" };
		}

		var tasks = getRunnableTasks();

		for( var taskKey in tasks ){
			runTask( taskKey );
		}

		return { tasksStarted=tasks };
	}

	public string function addTaskToStatusDb( required string taskKey ) {
		var configuredTask = getTask( arguments.taskKey );

		return _getTaskDao().insertData( data={
			  task_key           = arguments.taskKey
			, next_run           = getNextRunDate( arguments.taskKey )
			, enabled            = true
			, is_running         = false
			, priority           = configuredTask.priority
			, crontab_definition = configuredTask.schedule
		} );
	}

	public numeric function removeTaskFromStatusDb( required string taskKey ) {
		return _getTaskDao().deleteData(
			filter = { task_key = arguments.taskKey }
		);
	}

	public string function getNextRunDate( required string taskKey, date lastRun=Now() ) {
		var task       = getTask( arguments.taskKey );

		if ( !task.isScheduled ) {
			return "";
		}

		var taskConfig = getTaskConfiguration( arguments.taskKey );
		var schedule   = Len( Trim( taskConfig.crontab_definition ?: "" ) ) ? taskConfig.crontab_definition : task.schedule;

		var cronTabExpression = _getCrontabExpressionObject( schedule );
		var lastRunJodaTime   = _createJodaTimeObject( arguments.lastRun );

		return cronTabExpression.nextTimeAfter( lastRunJodaTime  ).toDate();
	}

	public array function getAllTaskDetails() {
		var tasks       = _getConfiguredTasks();
		var taskDetails = [];
		var dbTaskInfo  = _getTaskDao().selectData(
			  selectFields = [ "task_key", "enabled", "is_running", "last_ran", "next_run", "last_run_time_taken", "was_last_run_success", "crontab_definition" ]
			, useCache     = false
		);
		var grouped = [];

		for( var dbRecord in dbTaskInfo ){
			var detail = dbRecord;
			detail.append( tasks[ detail.task_key ] ?: {} );
			detail.schedule = _cronTabExpressionToHuman( Len( Trim( detail.crontab_definition ) ) ? detail.crontab_definition : detail.schedule );
			detail.is_running = taskIsRunning( detail.task_key );
			if( detail.is_running ){
				detail.taskHistoryId = getActiveHistoryIdForTask( detail.task_key );
			}
			taskDetails.append( detail );
		}

		taskDetails.sort( function( a, b ){
			if ( a.displayGroup == b.displayGroup ) {
				return a.name < b.name ? -1 : 1;
			}

			return a.displayGroup < b.displayGroup ? -1 : 1;
		} );

		for( var task in taskDetails ) {
			if ( !grouped.len() || grouped[ grouped.len() ].id != task.displayGroup ) {
				var groupId = Len( Trim( task.displayGroup ) ) ? task.displayGroup : "default";

				grouped.append({
					  id          = groupId
					, slug        = $slugify( groupId )
					, title       = $translateResource( "taskmanager.taskgroups:#groupId#.title", groupId )
					, description = $translateResource( "taskmanager.taskgroups:#groupId#.description", "" )
					, stats       = { total=0, success=0, fail=0, running=0, neverRun=0 }
					, tasks       = []
					, iconClass   = "fa-check green"
				});
			}

			var currentGroup = grouped[ grouped.len() ];
			currentGroup.tasks.append( task );
			currentGroup.stats.total++;
			if ( IsBoolean( task.was_last_run_success ) ) {
				currentGroup.stats[ task.was_last_run_success ? "success" : "fail" ]++;
			} else {
				currentGroup.stats.neverRun++;
			}

			if ( task.is_running ) {
				currentGroup.stats.running++;
			}
		}

		grouped.sort( function( a, b ){
			return a.title < b.title ? -1 : 1;
		} );

		for( var group in grouped ) {
			if ( group.stats.running ) {
				group.iconClass = "fa-rotate-right grey";
			} else if ( group.stats.fail || group.stats.neverRun ) {
				group.iconClass = "fa-times-circle red";
			}
		}

		return grouped;
	}

	public numeric function disableTask( required string taskKey ) {
		return _getTaskDao().updateData(
			  filter = { task_key = arguments.taskKey }
			, data   = { enabled = false }
		);
	}

	public numeric function enableTask( required string taskKey ) {
		return _getTaskDao().updateData(
			  filter = { task_key = arguments.taskKey }
			, data   = { enabled = true }
		);
	}

	public string function createLogHtml( required string log, numeric fetchAfterLines=0 ) {
		var logArray = ListToArray( arguments.log, Chr(10) );
		var outputArray = [];

		for( var i=arguments.fetchAfterLines+1; i <= logArray.len(); i++ ){
			var line = logArray[ i ];
			var logClass = LCase( ReReplace( line, '^\[(.*?)\].*$', '\1' ) );
			var dateTimeRegex = "(\[20[0-9]{2}\-[0-9]{2}\-[0-9]{2}\s[0-9]{2}:[0-9]{2}:[0-9]{2}\])";

			line = ReReplace( line, dateTimeRegex, '<span class="task-log-datetime">\1</span>' );
			line = '<span class="line-number">#i#.</span> <span class="task-log-line task-log-#logClass#">' & line & '</span>';

			outputArray.append( line );
		}

		return outputArray.toList( Chr(10) );
	}

	public struct function getStats() {
		var scheduleEnabled   = _getSystemConfigurationService().getSetting( "taskmanager", "scheduledtasks_enabled" );
		var tasks             = _getTaskDao().selectData();
		var historyDao        = _getTaskHistoryDao();
		var failureCount      = 0;
		var successCount      = 0;
		var disabledCount     = 0;
		var neverRunCount     = 0;

		for( var task in tasks ) {
			if ( IsBoolean( task.was_last_run_success ?: "" ) ) {
				if ( task.was_last_run_success ) {
					successCount++;
				} else if ( !task.enabled ) {
					disabledCount++;
				} else if ( !IsDate( task.last_ran ) ){
					neverRunCount++;
				} else {
					failureCount++;
				}
			}
		}

		var history = historyDao.selectData( selectFields=[
			  "Sum( time_taken ) as total_time_taken"
			, "Avg( time_taken ) as avg_time_taken"
			, "Count( id ) as total_count"
		] );
		var historySuccesses = historyDao.selectData(
			  filter = { success = true }
			, selectFields = [ "Count(*) as total" ]
		);

		return {
			  "taskmanager.schedule.enabled" = ( IsBoolean( scheduleEnabled ) && scheduleEnabled ) ? 1 : 0
			, "taskmanager.failure.count"    = failureCount
			, "taskmanager.success.count"    = successCount
			, "taskmanager.disabled.count"   = disabledCount
			, "taskmanager.neverrun.count"   = neverRunCount
			, "taskmanager.failure.perc"     = ( history.total_count ? ( ( ( history.total_count-historySuccesses.total ) / history.total_count ) * 100 ) : 0 )
			, "taskmanager.success.perc"     = ( history.total_count ? ( ( historySuccesses.total / history.total_count ) * 100 ) : 0 )
			, "taskmanager.total.time"       = Val( history.total_time_taken )
			, "taskmanager.avg.time"         = Val( history.avg_time_taken )
		};
	}

	public boolean function canShutdown( required boolean force ) {
		if ( !arguments.force && tasksAreRunning() ) {
			throw(
				  type    = "preside.reload.taskmanager.running"
				, message = "The application has been prevented from reloading because one or more tasks are running in the task manager."
				, detail  = "Either: reload the application with the &force URL parameter; manually stop all tasks before reloading the application; or, await their completion."
			);
		}

		return true;
	}

	public void function shutdown() {
		if ( tasksAreRunning() ) {
			killAllRunningTasks( timeout=1000 );
		}
	}

// PRIVATE HELPERS
	private any function _createJodaTimeObject( required date cfmlDateTime ) {
		return CreateObject( "java", "org.joda.time.DateTime", _getLib() ).init( cfmlDateTime );
	}

	private any function _getCrontabExpressionObject( required string expression ) {
		return CreateObject( "java", "fc.cron.CronExpression", _getLib() ).init( arguments.expression );
	}

	private void function _initialiseDb() {
		ensureTasksExistInStatusDb();
	}

	private date function _getOperationDate() {
		return Now();
	}

	private string function _cronTabExpressionToHuman( required string expression ) {
		if ( arguments.expression == "disabled" ) {
			return "disabled";
		}
		return CreateObject( "java", "net.redhogs.cronparser.CronExpressionDescriptor", _getLib() ).getDescription( arguments.expression );
	}

	private string function _getScheduledTaskUrl( required string siteId ) {
		var siteSvc    = _getSiteService();
		var site       = siteSvc.getSite( Len( Trim( arguments.siteId ) ) ? arguments.siteId : siteSvc.getActiveSiteId() );
		var serverName = ( site.domain ?: cgi.server_name );

		return "http://" & serverName & "/taskmanager/runtasks/";
	}

	private array function _getLib() {
		return [
			  "/preside/system/services/taskmanager/lib/cron-parser-2.6-SNAPSHOT.jar"
			, "/preside/system/services/taskmanager/lib/commons-lang3-3.3.2.jar"
			, "/preside/system/services/taskmanager/lib/joda-time-2.9.4.jar"
			, "/preside/system/services/taskmanager/lib/cron-1.0.jar"
		];
	}

	private boolean function _taskIsRunningOnLocalMachine( required any task ){
		var runningTasks = _getRunningTasks();
		var threadRef    = runningTasks[ task.running_thread ].thread ?: NullValue();

		if ( IsNull( threadRef ) ) {
			return false;
		}
		try {
			return !threadRef.isDone() && !threadRef.isCancelled();
		} catch( any e ) {
			_getErrorLogService().raiseError( e );
		}

		return false;
	}

	private void function _setActiveSite(){
		if ( $isFeatureEnabled( "sites" ) ) {
			var event       = $getRequestContext();
			var siteContext = $getPresideSetting( "taskmanager", "site_context" );

			if ( Len( Trim( siteContext ) ) ) {
				event.setSite( _getSiteService().getSite( siteContext ) );
				return;
			}

			event.autoSetSiteByHost();
		}
	}

// GETTERS AND SETTERS
	private struct function _getConfiguredTasks() {
		return _configuredTasks;
	}
	private void function _setConfiguredTasks( required struct configuredTasks ) {
		_configuredTasks = arguments.configuredTasks;
	}

	private any function _getController() {
		return _controller;
	}
	private void function _setController( required any controller ) {
		_controller = arguments.controller;
	}

	private any function _getTaskDao() {
		return _taskDao;
	}
	private void function _setTaskDao( required any taskDao ) {
		_taskDao = arguments.taskDao;
	}

	private any function _getTaskHistoryDao() {
		return _taskHistoryDao;
	}
	private void function _setTaskHistoryDao( required any taskHistoryDao ) {
		_taskHistoryDao = arguments.taskHistoryDao;
	}

	private any function _getSystemConfigurationService() {
		return _systemConfigurationService;
	}
	private void function _setSystemConfigurationService( required any systemConfigurationService ) {
		_systemConfigurationService = arguments.systemConfigurationService;
	}

	private any function _getLogger( string logId="", string taskKey="" ) {
		var taskRunId = Len( Trim( arguments.logId ) ) ? arguments.logId : getActiveHistoryIdForTask( arguments.taskKey );

		return new TaskManagerLoggerWrapper(
			  logboxLogger   = _logger
			, taskRunId      = taskRunId
			, taskHistoryDao = _getTaskHistoryDao()
		);
	}
	private void function _setLogger( required any logger ) {
		_logger = arguments.logger;
	}

	private any function _getErrorLogService() {
		return _errorLogService;
	}
	private void function _setErrorLogService( required any errorLogService ) {
		_errorLogService = arguments.errorLogService;
	}

	private any function _getSiteService() {
		return _siteService;
	}
	private void function _setSiteService( required any siteService ) {
		_siteService = arguments.siteService;
	}

	private string function _getMachineId() {
		return _machineId;
	}
	private void function _setMachineId() {
		var localHost = CreateObject("java", "java.net.InetAddress").getLocalHost();

		_machineId = Left( localHost.getHostAddress() & "-" & localHost.getHostName(), 255 );
	}

	private any function _getTaskScheduler() {
		return _taskScheduler;
	}
	private void function _setTaskScheduler( required any taskScheduler ) {
		_taskScheduler = arguments.taskScheduler;
	}

	private struct function _getRunningTasks() {
		return _runningTasks;
	}
	private void function _setRunningTasks( required struct runningTasks ) {
		_runningTasks = arguments.runningTasks;
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

}