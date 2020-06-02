component extends="testbox.system.BaseSpec" {

	public void function run() {

		describe( "init()", function(){
			it( "should ensure db is up to date with all configured tasks", function(){
				var tm = _getTaskManagerService();

				expect( tm.$callLog()._initialiseDb.len() ).toBe( 1 );
			} );
		} );

		describe( "listTasks()", function(){
			it( "should return an array of configured tasks", function(){
				var tasks = {
					  dothis          = { handler="sometask"             , frequency="*/10 * * * *" }
					, doSomethingElse = { handler="anothertask.something", frequency="43 2 * * *"   }
				};
	 			var tm       = _getTaskManagerService( tasks );
	 			var expected = [ "doSomethingElse", "doThis" ];
	 			var tasks    = tm.listTasks();

	 			tasks.sort( "textnocase" );

	 			expect( tasks ).toBe( expected );
			} );

			it( "should filter tasks by exclusivity group when passed", function(){
				var tasks = {
					  dothis          = { handler="sometask"             , frequency="*/10 * * * *", exclusivityGroup="test1" }
					, doSomethingElse = { handler="anothertask.something", frequency="43 2 * * *"  , exclusivityGroup="test2" }
				};
	 			var tm       = _getTaskManagerService( tasks );
	 			var expected = [ "doSomethingElse" ];
	 			var tasks    = tm.listTasks( exclusivityGroup="test2" );

	 			tasks.sort( "textnocase" );

	 			expect( tasks ).toBe( expected );
			} );
		} );

		describe( "getTask()", function(){
			it( "should return details of the given task", function(){
				var tasks = {
					  dothis     	  = { handler="sometask"             , frequency="*/10 * * * *" }
					, doSomethingElse = { handler="anothertask.something", frequency="43 2 * * *" }
				};
	 			var tm = _getTaskManagerService( tasks );

	 			expect( tm.getTask( "dothis" ) ).toBe( tasks.dothis );
			} );

			it( "should throw an informative error when the task does not exist", function(){
				var tm = _getTaskManagerService();

				expect( function(){
					tm.getTask( "sometask" );
				} ).toThrow( type="TaskManager.missing.task" );
			} );
		} );

		describe( "taskExists()", function(){
			it( "should return false when task does not exist", function(){
				var tasks = {
					  dothis     	  = { handler="sometask"             , frequency="*/10 * * * *" }
					, doSomethingElse = { handler="anothertask.something", frequency="43 2 * * *" }
				};
	 			var tm = _getTaskManagerService( tasks );

	 			expect( tm.taskExists( "anotherTask" ) ).toBeFalse();
			} );

			it( "should return true when the task does exist", function(){
				var tasks = {
					  dothis     	  = { handler="sometask"             , frequency="*/10 * * * *" }
					, doSomethingElse = { handler="anothertask.something", frequency="43 2 * * *" }
				};
	 			var tm = _getTaskManagerService( tasks );

	 			expect( tm.taskExists( "doSomethingElse" ) ).toBeTrue();
			} );
		} );

		describe( "taskIsRunning", function(){
			it( "should return true when the DB entry says task is running", function(){
				var tm = _getTaskManagerService();
				var taskKey = "somekey";
				var nowish = Now();

				tm.$( "taskRunIsExpired", false );
				tm.$( "taskThreadIsRunning", true );
				mockTaskDao.$( "dataExists" ).$args( filter = { task_key=taskKey, is_running=true } ).$results( true );

				expect( tm.taskIsRunning( taskKey ) ).toBe( true );
			} );

			it( "should return false when the DB entry says task is not running", function(){
				var tm = _getTaskManagerService();
				var taskKey = "somekey";
				var nowish = Now();

				tm.$( "taskRunIsExpired", false );
				mockTaskDao.$( "dataExists" ).$args( filter = { task_key=taskKey, is_running=true } ).$results( false );

				expect( tm.taskIsRunning( taskKey ) ).toBe( false );
			} );
		} );

		describe( "runTaskWithinThread()", function(){
			it( "should call the handler defined for the task, passing additional args set", function(){
				var tm         = _getTaskManagerService();
				var taskKey    = "syncEvents";
				var task       = { event="sync.events", name="My task", timeout=120 };
				var logId      = CreateUUId();
				var args       = { test=true, blah=CreateUUId() };
				var taskConfig = { crontab_definition = "* */10 * * * *", timeout=120 };

				tm.$( "getTask" ).$args( taskKey ).$results( task );
				tm.$( "getTaskConfiguration" ).$args( taskKey ).$results( taskConfig );
				tm.$( "taskIsRunning" ).$args( taskKey ).$results( false );
				mockColdbox.$( "runEvent", true );
				tm.$( "markTaskAsRunning" );
				tm.$( "markTaskAsCompleted" );
				tm.$( "createTaskHistoryLog", logId );

				tm.runTaskWithinThread( taskKey=taskKey, args=args, threadId=CreateUUId(), logger=mockLogger );
				sleep( 200 );

				expect( mockColdbox.$callLog().runEvent.len() ).toBe( 1 );
				expect( mockColdbox.$callLog().runEvent[1] ).toBe( {
					  event          = task.event
					, private        = true
					, eventArguments = { logger=mockLogger, args=args }
				} );
			} );

			it( "should flag the task as complete and unsuccessful when task run throws an error", function(){
				var tm       = _getTaskManagerService();
				var taskKey = "syncEvents";
				var task     = { event="sync.events", name="Sync events", timeout=120 };
				var logId   = CreateUUId();
				var taskConfig = { crontab_definition = "* */10 * * * *", timeout=120 };

				tm.$( "getTask" ).$args( taskKey ).$results( task );
				tm.$( "getTaskConfiguration" ).$args( taskKey ).$results( taskConfig );
				tm.$( "taskIsRunning" ).$args( taskKey ).$results( false );
				mockColdbox.$( method="runEvent", throwException=true );
				tm.$( "markTaskAsRunning" );
				tm.$( "markTaskAsCompleted" );
				tm.$( "createTaskHistoryLog", logId );
				tm.$( "_getLogger" ).$args( logId ).$results( mockLogger );

				try {
					tm.runTaskWithinThread( taskKey=taskKey, args={}, threadId=CreateUUId(), logger=mockLogger );
					sleep( 1000 );
				} catch( any e ) {}

				expect( tm.$callLog().markTaskAsCompleted.len() ).toBe( 1 );
				expect( tm.$callLog().markTaskAsCompleted[1].taskKey ).toBe( taskKey );
				expect( tm.$callLog().markTaskAsCompleted[1].success ).toBe( false );
			} );

			it( "should flag the task as complete and unsuccessful when task run returns false", function(){
				var tm       = _getTaskManagerService();
				var taskKey = "syncEvents";
				var task     = { event="sync.events", name="I like testing", timeout=120 };
				var logId   = CreateUUId();
				var taskConfig = { crontab_definition = "* */10 * * * *", timeout=120 };

				tm.$( "getTask" ).$args( taskKey ).$results( task );
				tm.$( "getTaskConfiguration" ).$args( taskKey ).$results( taskConfig );
				tm.$( "taskIsRunning" ).$args( taskKey ).$results( false );
				mockColdbox.$( "runEvent", false );
				tm.$( "markTaskAsRunning" );
				tm.$( "markTaskAsCompleted" );
				tm.$( "createTaskHistoryLog", logId );
				tm.$( "_getLogger" ).$args( logId ).$results( mockLogger );

				tm.runTaskWithinThread( taskKey=taskKey, args={}, threadId=CreateUUId(), logger=mockLogger );
				sleep( 200 );

				expect( tm.$callLog().markTaskAsCompleted.len() ).toBe( 1 );
				expect( tm.$callLog().markTaskAsCompleted[1].taskKey ).toBe( taskKey );
				expect( tm.$callLog().markTaskAsCompleted[1].success ).toBe( false );
			} );

			it( "should pass time taken to the markTaskAsCompleted() method", function(){
				var tm       = _getTaskManagerService();
				var taskKey = "syncEvents";
				var task     = { event="sync.events", name="This rocks", timeout=120 };
				var logId   = CreateUUId();
				var taskConfig = { crontab_definition = "* */10 * * * *", timeout=120 };

				tm.$( "getTask" ).$args( taskKey ).$results( task );
				tm.$( "getTaskConfiguration" ).$args( taskKey ).$results( taskConfig );
				tm.$( "taskIsRunning" ).$args( taskKey ).$results( false );
				mockColdbox.$( "runEvent", false );
				tm.$( "markTaskAsRunning" );
				tm.$( "markTaskAsCompleted" );
				tm.$( "createTaskHistoryLog", logId );
				tm.$( "_getLogger" ).$args( logId ).$results( mockLogger );

				tm.runTaskWithinThread( taskKey=taskKey, args={}, threadId=CreateUUId(), logger=mockLogger );
				sleep( 200 );

				expect( tm.$callLog().markTaskAsCompleted.len() ).toBe( 1 );
				expect( tm.$callLog().markTaskAsCompleted[1].keyExists( "timeTaken" ) ).toBe( true );
				expect( tm.$callLog().markTaskAsCompleted[1].timeTaken ).toBeNumeric();
			} );

			it( "should do nothing when task is already running", function(){
				var tm       = _getTaskManagerService();
				var taskKey = "syncEvents";
				var task     = { event="sync.events", name="already running task", timeout=120 };
				var logId   = CreateUUId();
				var taskConfig = { crontab_definition = "* */10 * * * *", timeout=120 };

				tm.$( "getTask" ).$args( taskKey ).$results( task );
				tm.$( "getTaskConfiguration" ).$args( taskKey ).$results( taskConfig );
				tm.$( "taskIsRunning" ).$args( taskKey ).$results( true );
				mockColdbox.$( "runEvent", false );

				tm.$( "markTaskAsRunning" );
				tm.$( "markTaskAsCompleted" );
				tm.$( "createTaskHistoryLog", logId );
				tm.$( "_getLogger" ).$args( logId ).$results( mockLogger );

				tm.runTask( taskKey );
				sleep( 200 );

				expect( tm.$callLog().markTaskAsCompleted.len() ).toBe( 0 );
				expect( tm.$callLog().markTaskAsRunning.len() ).toBe( 0 );
				expect( mockColdbox.$callLog().runEvent.len() ).toBe( 0 );


			} );
		} );

		describe( "listTasksStoredInStatusDb()", function(){
			it( "should return array of task task_key's that have status entries in the database", function(){
				var tm             = _getTaskManagerService();
				var dummyRecordset = QueryNew( 'task_key', 'varchar', [ [ "mytask" ], [ "anothertask" ], [ "andanother" ] ] );
				var expected       = [ "mytask", "anothertask", "andanother" ];

				mockTaskDao.$( "selectData" ).$args(
					selectFields = [ "task_key" ]
				).$results( dummyRecordset );

				expect( tm.listTasksStoredInStatusDb() ).toBe( expected );
			} );
		} );

		describe( "ensureTasksExistInStatusDb()", function(){
			it( "should insert records for configured tasks that do not exist in the database", function(){
				var tm = _getTaskManagerService();

				tm.$( "listTasks"                , [ "task_a", "task_b", "task_c", "task_d" ] );
				tm.$( "listTasksStoredInStatusDb", [ "task_a", "task_c" ] );
				tm.$( "addTaskToStatusDb", CreateUUId() );

				tm.ensureTasksExistInStatusDb();

				expect( tm.$callLog().addTaskToStatusDb.len() ).toBe( 2 );
				expect( tm.$callLog().addTaskToStatusDb[1] ).toBe( [ "task_b" ] );
				expect( tm.$callLog().addTaskToStatusDb[2] ).toBe( [ "task_d" ] );
			} );

			it( "should delete tasks from the DB when they do not exist in configuration", function(){
				var tm = _getTaskManagerService();

				tm.$( "listTasks"                , [ "task_a", "task_b", "task_c", "task_d" ] );
				tm.$( "listTasksStoredInStatusDb", [ "task_a", "task_a1", "task_c", "task_e", "task_g" ] );
				tm.$( "addTaskToStatusDb", CreateUUId() );
				tm.$( "removeTaskFromStatusDb", 1 );

				tm.ensureTasksExistInStatusDb();

				expect( tm.$callLog().removeTaskFromStatusDb.len() ).toBe( 3 );
				expect( tm.$callLog().removeTaskFromStatusDb[1] ).toBe( [ "task_a1" ] );
				expect( tm.$callLog().removeTaskFromStatusDb[2] ).toBe( [ "task_e" ] );
				expect( tm.$callLog().removeTaskFromStatusDb[3] ).toBe( [ "task_g" ] );
			} );
		} );

		describe( "removeTaskFromStatusDb()", function(){
			it( "should call deleteData() on the dao, filtering on the task task_key", function(){
				var tm               = _getTaskManagerService();
				var taskKey          = "sometask";
				var deleteDataResult = 5; // fake, of course - it would only ever delete a single record

				mockTaskDao.$( "deleteData" ).$args(
					filter = { task_key = taskKey }
				).$results( deleteDataResult );

				expect( tm.removeTaskFromStatusDb( taskKey ) ).toBe( deleteDataResult );
				expect( mockTaskDao.$callLog().deleteData.len() ).toBe( 1 );
				expect( mockTaskDao.$callLog().deleteData[1] ).toBe( { filter={ task_key = taskKey } } );
			} );
		} );

		describe( "getNextRunDate()", function(){
			it( "should take a cron expression and last run date and run that through our java cron library", function(){
				var tm             = _getTaskManagerService();
				var lastRun        = "2014-10-24T09:03:13";
				var taskKey        = "someKey";
				var task           = { schedule = "* */5 * * * *", isScheduled=true };
				var config         = { crontab_definition = "", timeout=100 };

				tm.$( "getTask" ).$args( taskKey ).$results( task );
				tm.$( "getTaskConfiguration" ).$args( taskKey ).$results( config );

				var nextRun = tm.getNextRunDate( taskKey, lastRun );

				expect( nextRun ).toBe( "2014-10-24 09:05:00" );
			} );

			it( "shoud use the current date when no last run date passed", function(){
				var tm             = _getTaskManagerService();
				var taskKey        = "someKey";
				var task           = { schedule = "* */5 * * * *", isScheduled=true };
				var rightNow       = Now();
				var config         = { crontab_definition = "", timeout=100  };

				tm.$( "getTask" ).$args( taskKey ).$results( task );
				tm.$( "getTaskConfiguration" ).$args( taskKey ).$results( config );

				var nextRun = tm.getNextRunDate( taskKey );

				expect( DateDiff( "n", rightNow, nextRun ) >= 0  ).toBe( true );
			} );

			it( "should use saved crontab over coded crontab where available", function(){
				var tm             = _getTaskManagerService();
				var lastRun        = "2014-10-24T09:03:13";
				var taskKey        = "someKey";
				var task           = { schedule = "* */5 * * * *", isScheduled=true };
				var config         = { crontab_definition = "* */10 * * * *", timeout=100  };

				tm.$( "getTask" ).$args( taskKey ).$results( task );
				tm.$( "getTaskConfiguration" ).$args( taskKey ).$results( config );

				var nextRun = tm.getNextRunDate( taskKey, lastRun );

				expect( nextRun ).toBe( "2014-10-24 09:10:00" );
			} );

			it( "should return an empty string when task is not a scheduled task", function(){
				var tm             = _getTaskManagerService();
				var lastRun        = "2014-10-24T09:03:13";
				var taskKey        = "someKey";
				var task           = { schedule = "disabled", isScheduled=false };
				var config         = { crontab_definition = "* */10 * * * *", timeout=100  };

				tm.$( "getTask" ).$args( taskKey ).$results( task );
				tm.$( "getTaskConfiguration" ).$args( taskKey ).$results( config );

				var nextRun = tm.getNextRunDate( taskKey, lastRun );

				expect( nextRun ).toBe( "" );
			} );
		} );

		describe( "addTaskToStatusDb()", function(){
			it( "should insert a new record into the task db", function(){
				var tm          = _getTaskManagerService();
				var taskKey     = "sometask";
				var newRecordId = CreateUUId();
				var task        = { event="sync.events", priority=0, schedule="* 13 2 * * *", timeout=100 };
				var nextRunDate = DateAdd( "d", 1, Now() );

				tm.$( "getTask" ).$args( taskKey ).$results( task );
				tm.$( "getNextRunDate" ).$args( taskKey ).$results( nextRunDate );

				mockTaskDao.$( "insertData" ).$args( data = {
					  task_key           = taskKey
					, next_run           = nextRunDate
					, is_running         = false
					, enabled            = true
					, priority           = task.priority
					, crontab_definition = task.schedule
				} ).$results( newRecordId );

				expect( tm.addTaskToStatusDb( taskKey ) ).toBe( newRecordId );
			} );
		} );

		describe( "markTaskAsRunning()", function(){
			it( "should mark the db record as running", function(){
				var tm          = _getTaskManagerService();
				var taskKey     = "sometask";
				var expires     = Now();
				var nextRunDate = DateAdd( "h", 1, expires );
				var threadId    = CreateUUId();
				var machineId   = CreateUUId();

				tm.$( "getNextRunDate" ).$args( taskKey ).$results( nextRunDate );
				tm.$( "_getMachineId", machineId );

				mockTaskDao.$( "updateData" ).$args(
					  data = { is_running = true, next_run=nextRunDate, running_thread=threadId, running_machine=machineId }
					, filter = { task_key = taskKey }
				).$results( 1 );

				expect( tm.markTaskAsRunning( taskKey, threadId ) ).toBe( 1 );
				expect( mockTaskDao.$callLog().updateData.len() ).toBe( 1 );
			} );
		} );

		describe( "markTaskAsCompleted()", function(){
			it( "should mark the db record as not running", function(){
				var tm          = _getTaskManagerService();
				var taskKey     = "sometask";

				tm.$( "getNextRunDate" );
				tm.$( "completeTaskHistoryLog" );

				mockTaskDao.$( "selectData" ).$args( filter={ task_key=taskKey } ).$results( QueryNew('') );
				mockTaskDao.$( "updateData", 1 );

				tm.markTaskAsCompleted( taskKey, true, 36 )

				expect( mockTaskDao.$callLog().updateData.len() ).toBe( 1 );
				expect( mockTaskDao.$callLog().updateData[1].filter ).toBe( { task_key = taskKey });
				expect( mockTaskDao.$callLog().updateData[1].data.is_running ).toBe( false );
			} );

			it( "should set the completed date to now", function(){
				var tm          = _getTaskManagerService();
				var taskKey     = "sometask";
				var rightNow    = Now();

				tm.$( "getNextRunDate" );
				tm.$( "_getOperationDate", rightNow );
				tm.$( "completeTaskHistoryLog" );

				mockTaskDao.$( "selectData" ).$args( filter={ task_key=taskKey } ).$results( QueryNew('') );
				mockTaskDao.$( "updateData", 1 );

				tm.markTaskAsCompleted( taskKey, true, 5363 );

				expect( mockTaskDao.$callLog().updateData.len() ).toBe( 1 );
				expect( mockTaskDao.$callLog().updateData[1].data.last_ran ).toBe( rightNow );
			} );

			it( "should set the next run date to the date calculated by the getNextRunDate() method", function(){
				var tm          = _getTaskManagerService();
				var taskKey     = "sometask";
				var nextRunDate = DateAdd( "w", 1, Now() );

				tm.$( "getNextRunDate" ).$args( taskKey ).$results( nextRunDate );
				tm.$( "completeTaskHistoryLog" );

				mockTaskDao.$( "selectData" ).$args( filter={ task_key=taskKey } ).$results( QueryNew('') );
				mockTaskDao.$( "updateData", 1 );

				tm.markTaskAsCompleted( taskKey, true, 345 );

				expect( mockTaskDao.$callLog().updateData.len() ).toBe( 1 );
				expect( mockTaskDao.$callLog().updateData[1].data.next_run ).toBe( nextRunDate );
			} );

			it( "should set the success flag to true when success passed as true", function(){
				var tm          = _getTaskManagerService();
				var taskKey     = "sometask";

				tm.$( "getNextRunDate" );
				tm.$( "completeTaskHistoryLog" );

				mockTaskDao.$( "selectData" ).$args( filter={ task_key=taskKey } ).$results( QueryNew('') );
				mockTaskDao.$( "updateData", 1 );

				tm.markTaskAsCompleted( taskKey, true, 345 );

				expect( mockTaskDao.$callLog().updateData.len() ).toBe( 1 );
				expect( mockTaskDao.$callLog().updateData[1].data.was_last_run_success ).toBe( true );
			} );

			it( "should set the success flag to false when success passed as false", function(){
				var tm          = _getTaskManagerService();
				var taskKey     = "sometask";

				tm.$( "getNextRunDate" );
				tm.$( "completeTaskHistoryLog" );

				mockTaskDao.$( "selectData" ).$args( filter={ task_key=taskKey } ).$results( QueryNew('') );
				mockTaskDao.$( "updateData", 1 );

				tm.markTaskAsCompleted( taskKey, false, 5809 );

				expect( mockTaskDao.$callLog().updateData.len() ).toBe( 1 );
				expect( mockTaskDao.$callLog().updateData[1].data.was_last_run_success ).toBe( false );
			} );

			it( "should set the time taken field to the time taken", function(){
				var tm        = _getTaskManagerService();
				var taskKey   = "sometask";
				var timeTaken = 34658;

				tm.$( "getNextRunDate" );
				tm.$( "completeTaskHistoryLog" );

				mockTaskDao.$( "selectData" ).$args( filter={ task_key=taskKey } ).$results( QueryNew('') );
				mockTaskDao.$( "updateData", 1 );

				tm.markTaskAsCompleted( taskKey, false, timeTaken );

				expect( mockTaskDao.$callLog().updateData.len() ).toBe( 1 );
				expect( mockTaskDao.$callLog().updateData[1].data.last_run_time_taken ).toBe( timeTaken );
			} );

			it( "should add a task history record", function(){
				var tm        = _getTaskManagerService();
				var taskKey   = "sometask";
				var timeTaken = 34658;

				tm.$( "getNextRunDate" );
				tm.$( "completeTaskHistoryLog" );

				mockTaskDao.$( "selectData" ).$args( filter={ task_key=taskKey } ).$results( QueryNew('') );
				mockTaskDao.$( "updateData", 1 );

				tm.markTaskAsCompleted( taskKey, false, timeTaken );

				expect( tm.$callLog().completeTaskHistoryLog.len() ).toBe( 1 );
				expect( tm.$callLog().completeTaskHistoryLog[1] ).toBe( [ taskKey, false, timeTaken ]  );
			} );
		} );

		describe( "getRunnableTasks()", function(){
			it( "should return an array of all the tasks that require running based on their database status, taking mutual exclusivity into account", function(){
				var tm             = _getTaskManagerService({
					  task_1 = { exclusivityGroup="test" }
					, task_2 = { exclusivityGroup="none" }
					, task_3 = { exclusivityGroup="group" }
					, task_4 = { exclusivityGroup="group" }
					, task_5 = { exclusivityGroup="test" }
				});
				var dummyRecordset = QueryNew( "task_key", "varchar", [["task_1"], ["task_2"],["task_3"], ["task_4"] ]);
				var tasks          = [ "task_2", "task_3" ];
				var rightNow       = Now();

				tm.$( "_getOperationDate", rightNow );
				tm.$( "tasksAreRunning" ).$args( "test" ).$results( true );
				tm.$( "tasksAreRunning" ).$args( "group" ).$results( false );

				mockTaskDao.$( "selectData" ).$args(
					  selectFields = [ "task_key" ]
					, filter       = "enabled = :enabled and is_running = :is_running and next_run < :next_run"
					, filterParams = { enabled=true, is_running=false, next_run=rightNow }
					, orderBy      = "priority desc"
					, useCache     = false
				).$results( dummyRecordset );

				expect( tm.getRunnableTasks() ).toBe( tasks );
			} );
		} );

		describe( "runScheduledTasks()", function(){
			it( "should do nothing when scheduled tasks are disabled", function(){
				var tm    = _getTaskManagerService();
				var tasks = [ "task_a", "task_b", "task_c" ];

				tm.$( "getRunnableTasks", tasks );
				tm.$( "runTask" );

				mockSysConfigService.$( "getCategorySettings" ).$args( "taskmanager" ).$results({
					  scheduledtasks_enabled = false
					, site_context           = CreateUUId()
				});

				var result = tm.runScheduledTasks();
				expect( result.tasksStarted ).toBe(  [] );

				expect( tm.$callLog().getRunnableTasks.len() ).toBe( 0 );
				expect( tm.$callLog().runTask.len() ).toBe( 0 );
			} );

			it( "should run each runnable task", function(){
				var tm     = _getTaskManagerService();
				var tasks  = [ "task_a", "task_b", "task_c" ];
				var siteId = CreateUUId();

				mockSysConfigService.$( "getCategorySettings" ).$args( "taskmanager" ).$results({
					  scheduledtasks_enabled = true
					, site_context           = siteId
				});
				mockSiteService.$( "getActiveSiteId", siteId );

				tm.$( "getRunnableTasks", tasks );
				tm.$( "runTask" );

				tm.runScheduledTasks();

				expect( tm.$callLog().runTask.len() ).toBe( 3 );
			} );

			it( "should return an array of the tasks that were started", function(){
				var tm     = _getTaskManagerService();
				var tasks  = [ "task_a", "task_b", "task_c" ];
				var siteId = CreateUUId();

				mockSysConfigService.$( "getCategorySettings" ).$args( "taskmanager" ).$results({
					  scheduledtasks_enabled = true
					, site_context           = siteId
				});
				mockSiteService.$( "getActiveSiteId", siteId );

				tm.$( "getRunnableTasks", tasks );
				tm.$( "runTask" );

				var result = tm.runScheduledTasks();

				expect( result.tasksStarted ).toBe( tasks );

			} );
		} );
	}

	private any function _getTaskManagerService( struct dummyConfig={} ) {
		var mockBox = getMockBox();

		mockColdbox          = mockbox.createStub();
		mockRc               = mockbox.createStub();
		mockTaskDao          = mockbox.createStub();
		mockTaskHistoryDao   = mockbox.createStub();
		configWrapper        = mockbox.createStub();
		mockSysConfigService = mockbox.createStub();
		mockErrorLogService  = mockbox.createStub();
		mockSiteService      = mockbox.createStub();
		mockThreadUtil       = mockbox.createStub();
		mockExecutor         = mockbox.createStub();
		mockLogger           = _getMockLogger();

		configWrapper.$( "getConfiguredTasks", arguments.dummyConfig );
		mockSysConfigService.$( "getSetting" ).$args( "taskmanager", "scheduledtasks_enabled", false ).$results( true );
		mockErrorLogService.$( "raiseError" );
		mockSiteService.$( "getActiveSiteId", CreateUUId() );
		mockThreadUtil.$( "setThreadName" );
		mockThreadUtil.$( "setThreadRequestDefaults" );
		mockThreadUtil.$( "getCurrentThread", {} );

		var tm = mockBox.createMock( object=CreateObject( "preside.system.services.taskmanager.TaskManagerService" ) );

		tm.$( "_initialiseDb" );
		tm.$( "$getRequestContext", mockRc );
		tm.$( "$getErrorLogService", mockErrorLogService );
		tm.$( "$isFeatureEnabled" ).$args( "sslInternalHttpCalls" ).$results( true );
		tm.$( "_setActiveSite" );
		mockRc.$( "setUseQueryCache" );

		return tm.init(
			  configWrapper                = configWrapper
			, controller                   = mockColdbox
			, taskDao                      = mockTaskDao
			, taskHistoryDao               = mockTaskHistoryDao
			, systemConfigurationService   = mockSysConfigService
			, logger                       = mockLogger
			, errorLogService              = mockErrorLogService
			, siteService                  = mockSiteService
			, threadUtil                   = mockThreadUtil
			, executor                     = mockExecutor
		);
	}

	private any function _getMockLogger() {
		var logger = getMockBox().createStub();

		logger.$( "fatal"      );
		logger.$( "error"      );
		logger.$( "warn"       );
		logger.$( "info"       );
		logger.$( "debug"      );
		logger.$( "logMessage" );

		logger.$( "canFatal", true );
		logger.$( "canError", true );
		logger.$( "canWarn" , true );
		logger.$( "canInfo" , true );
		logger.$( "canDebug", true );

		return logger;
	}
}