component extends="testbox.system.BaseSpec" {

	public void function run() {
		describe( "runTask()", function(){
			it( "should call the handler defined for the task, passing additional args set, a special logger and special progress object for the task", function(){
				var service = _getService();
				var taskId  = CreateUUId();
				var event   = "some.handler.action";
				var args    = { test=CreateUUId(), fubar=123 };
				var taskDef = QueryNew( 'event,event_args,status', 'varchar,varchar,varchar', [ [ event, SerializeJson( args ), "pending" ] ] );

				_mockGetTask( taskId, taskDef );
				mockColdbox.$( "runEvent" );
				var mockProgress = _mockProgress( service, taskId );
				var mockLogger   = _mockLogger( service, taskId );

				service.$( "markTaskAsRunning" );
				service.$( "completeTask" );
				service.$( "failTask" );

				expect( service.runTask( taskId ) ).toBe( true );

				var log = mockColdbox.$callLog().runEvent;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( {
					  event          = event
					, eventArguments = { args=args, logger=mockLogger, progress=mockProgress }
					, private        = true
					, prepostExempt  = true
				} );
			} );

			it( "should mark the task as running during the process", function(){
				var service = _getService();
				var taskId  = CreateUUId();
				var event   = "some.handler.action";
				var args    = { test=CreateUUId(), fubar=123 };
				var taskDef = QueryNew( 'event,event_args,status', 'varchar,varchar,varchar', [ [ event, SerializeJson( args ), "pending" ] ] );
				var nowish  = Now();

				_mockGetTask( taskId, taskDef );
				mockColdbox.$( "runEvent" );
				var mockProgress = _mockProgress( service, taskId );
				var mockLogger   = _mockLogger( service, taskId );

				service.$( "markTaskAsRunning" );
				service.$( "completeTask" );
				service.$( "failTask" );
				service.$( "_now", nowish );

				service.runTask( taskId );

				log = service.$callLog().markTaskAsRunning;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( { taskId=taskId } );
			} );

			it( "should mark the task as complete when finished successfully", function(){
				var service = _getService();
				var taskId  = CreateUUId();
				var event   = "some.handler.action";
				var args    = { test=CreateUUId(), fubar=123 };
				var taskDef = QueryNew( 'event,event_args,status', 'varchar,varchar,varchar', [ [ event, SerializeJson( args ), "pending" ] ] );

				_mockGetTask( taskId, taskDef );
				mockColdbox.$( "runEvent" );
				var mockProgress = _mockProgress( service, taskId );
				var mockLogger   = _mockLogger( service, taskId );

				service.$( "completeTask" );
				service.$( "failTask" );
				service.$( "markTaskAsRunning" );

				service.runTask( taskId );

				log = service.$callLog().completeTask;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( { taskId=taskId } );
			} );

			it( "should fail the task and return false when the handler returns false", function(){
				var service = _getService();
				var taskId  = CreateUUId();
				var event   = "some.handler.action";
				var args    = { test=CreateUUId(), fubar=123 };
				var taskDef = QueryNew( 'event,event_args,status', 'varchar,varchar,varchar', [ [ event, SerializeJson( args ), "pending" ] ] );

				_mockGetTask( taskId, taskDef );
				mockColdbox.$( "runEvent", false );
				var mockProgress = _mockProgress( service, taskId );
				var mockLogger   = _mockLogger( service, taskId );

				service.$( "completeTask" );
				service.$( "failTask" );
				service.$( "markTaskAsRunning" );

				expect( service.runTask( taskId ) ).toBe( false );

				log = service.$callLog().completeTask;
				expect( log.len() ).toBe( 0 );

				log = service.$callLog().failTask;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( { taskId=taskId, error={} } );
			} );

			it( "should return false, fail the task and log error when an error is thrown during execution of the handler action", function(){
				var service = _getService();
				var taskId  = CreateUUId();
				var event   = "some.handler.action";
				var args    = { test=CreateUUId(), fubar=123 };
				var taskDef = QueryNew( 'event,event_args,status', 'varchar,varchar,varchar', [ [ event, SerializeJson( args ), "pending" ] ] );

				_mockGetTask( taskId, taskDef );
				var mockProgress = _mockProgress( service, taskId );
				var mockLogger   = _mockLogger( service, taskId );

				mockColdbox.$( "runEvent" ).$throws( type="SomeError", message="boo :(" );
				service.$( "$raiseError" );
				service.$( "completeTask" );
				service.$( "failTask" );
				service.$( "markTaskAsRunning" );
				mockLogger.$( "error" );

				expect( service.runTask( taskId ) ).toBe( false );

				var log = service.$callLog().$raiseError;
				expect( log.len() ).toBe( 1 );
				expect( log[1].error.type    ?: "" ).toBe( "SomeError" );
				expect( log[1].error.message ?: "" ).toBe( "boo :(" );

				log = service.$callLog().failTask;
				expect( log.len() ).toBe( 1 );
				expect( log[1].taskId ).toBe( taskId );
				expect( log[1].error.type    ?: "" ).toBe( "SomeError" );
				expect( log[1].error.message ?: "" ).toBe( "boo :(" );

				log = mockLogger.$callLog().error;
				expect( log.len() ).toBe( 1 );
			} );

			it( "should silenty raise an error and return false when the task is already running", function(){
				var service = _getService();
				var taskId  = CreateUUId();
				var event   = "some.handler.action";
				var args    = { test=CreateUUId(), fubar=123 };
				var taskDef = QueryNew( 'event,event_args,status', 'varchar,varchar,varchar', [ [ event, SerializeJson( args ), "running" ] ] );

				_mockGetTask( taskId, taskDef );
				var mockProgress = _mockProgress( service, taskId );
				var mockLogger   = _mockLogger( service, taskId );

				mockColdbox.$( "runEvent" );
				service.$( "$raiseError" );
				service.$( "completeTask" );
				service.$( "failTask" );
				service.$( "markTaskAsRunning" );

				expect( service.runTask( taskId ) ).toBe( false );
				expect( mockColdbox.$callLog().runEvent.len() ).toBe( 0 );

				var log = service.$callLog().$raiseError;
				expect( log.len() ).toBe( 1 );
				expect( log[1].error.type    ?: "" ).toBe( "AdHoTaskManagerService.task.already.running" );
				expect( log[1].error.message ?: "" ).toBe( "Task not run. The task with ID, [#taskId#], is already running." );
			} );

			it( "should set useQueryCache to false for the request to ensure query caching is not used throughout the process (by default)", function(){
				var service = _getService();
				var taskId  = CreateUUId();
				var event   = "some.handler.action";
				var args    = { test=CreateUUId(), fubar=123 };
				var taskDef = QueryNew( 'event,event_args,status', 'varchar,varchar,varchar', [ [ event, SerializeJson( args ), "pending" ] ] );

				_mockGetTask( taskId, taskDef );
				mockColdbox.$( "runEvent" );
				var mockProgress = _mockProgress( service, taskId );
				var mockLogger   = _mockLogger( service, taskId );

				service.$( "completeTask" );
				service.$( "failTask" );
				service.$( "markTaskAsRunning" );

				service.runTask( taskId );

				log = mockRequestContext.$callLog().setUseQueryCache;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( [ false ] );
			} );
		} );

		describe( "createTask()", function(){
			it( "should insert a new record into the adhoc task table and return the ID", function(){
				var service = _getService();
				var owner   = CreateUUId();
				var event   = "some.event";
				var args    = { test=CreateUUId(), foobar=[ 1, 2, CreateUUId() ] };
				var taskId  = CreateUUId();

				mockTaskDao.$( "insertData" ).$args( {
					  event               = event
					, event_args          = SerializeJson( _addMockRequestState( args ) )
					, admin_owner         = owner
					, web_owner           = ""
					, discard_on_complete = false
					, retry_interval      = "[]"
					, title               = ""
					, title_data          = "[]"
					, result_url          = ""
					, return_url          = ""
					, next_attempt_date   = ""
				} ).$results( taskId );

				expect( service.createTask(
					  adminOwner = owner
					, event      = event
					, args       = args
				) ).toBe( taskId );
			} );

			it( "should run the newly created task in a new thread if 'runNow' is passed and is 'true'", function(){
				var service = _getService();
				var owner   = CreateUUId();
				var event   = "some.event";
				var args    = { test=CreateUUId(), foobar=[ 1, 2, CreateUUId() ] };
				var taskId  = CreateUUId();

				mockTaskDao.$( "insertData" ).$args( {
					  event               = event
					, event_args          = SerializeJson( _addMockRequestState( args ) )
					, admin_owner         = ""
					, web_owner           = owner
					, discard_on_complete = true
					, retry_interval      = "[]"
					, next_attempt_date   = ""
					, title               = "myresource:export.title"
					, title_data          = '["test","this"]'
					, result_url          = "http://www.mysite.com/download/export/"
					, return_url          = "http://www.mysite.com/download/cancelled/"
				} ).$results( taskId );
				service.$( "runTaskInThread" );

				service.createTask(
					  webOwner          = owner
					, event             = event
					, args              = args
					, runNow            = true
					, discardOnComplete = true
					, title             = "myresource:export.title"
					, titleData         = [ "test", "this" ]
					, resultUrl         = "http://www.mysite.com/download/export/"
					, returnUrl         = "http://www.mysite.com/download/cancelled/"
				);

				var log = service.$callLog().runTaskInThread;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( { taskId=taskId } );
			} );

			it( "should replace {taskId} in task result URL with the newly created task ID", function(){
				var service = _getService();
				var owner   = CreateUUId();
				var event   = "some.event";
				var args    = { test=CreateUUId(), foobar=[ 1, 2, CreateUUId() ] };
				var taskId  = CreateUUId();
				var resultUrl = "https://www.mysite.com/task/result/?taskId={taskid}&really={taskid}";

				mockTaskDao.$( "insertData" ).$args( {
					  event               = event
					, event_args          = SerializeJson( _addMockRequestState( args ) )
					, admin_owner         = owner
					, web_owner           = ""
					, discard_on_complete = false
					, retry_interval      = "[]"
					, title               = ""
					, title_data          = "[]"
					, result_url          = resultUrl
					, return_url          = ""
					, next_attempt_date   = ""
				} ).$results( taskId );

				service.$( "setResultUrl" );

				service.createTask(
					  adminOwner = owner
					, event      = event
					, args       = args
					, resultUrl  = resultUrl
				);

				var log = service.$callLog().setResultUrl;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( {
					  taskId    = taskId
					, resultUrl = "https://www.mysite.com/task/result/?taskId=#taskId#&really=#taskId#"
				} );
			} );

			it( "should turn single struct retry interval to an array", function(){
				var service = _getService();
				var owner   = CreateUUId();
				var event   = "some.event";
				var args    = { test=CreateUUId(), foobar=[ 1, 2, CreateUUId() ] };
				var taskId  = CreateUUId();

				mockTaskDao.$( "insertData" ).$args( {
					  event               = event
					, event_args          = SerializeJson( _addMockRequestState( args ) )
					, admin_owner         = ""
					, web_owner           = ""
					, discard_on_complete = false
					, retry_interval      = SerializeJson( [{ tries=4, interval=120 }] )
					, title               = ""
					, title_data          = "[]"
					, next_attempt_date   = ""
					, result_url          = ""
					, return_url          = ""
				} ).$results( taskId );

				expect( service.createTask(
					  event         = event
					, args          = args
					, retryInterval = { tries=4, interval=120 }
				) ).toBe( taskId );
			} );

			it( title="should convert CreateTimeSpan() entries to seconds in the retry interval configuration", skip=true, body=function(){
				var service = _getService();
				var owner   = CreateUUId();
				var event   = "some.event";
				var args    = { test=CreateUUId(), foobar=[ 1, 2, CreateUUId() ] };
				var taskId  = CreateUUId();

				mockTaskDao.$( "insertData" ).$args( {
					  event               = event
					, event_args          = SerializeJson( _addMockRequestState( args ) )
					, admin_owner         = ""
					, web_owner           = ""
					, discard_on_complete = false
					, retry_interval      = SerializeJson( [{ tries=4, interval=CreateTimeSpan( 0, 0, 3, 45 ).getSeconds() }] )
					, title               = ""
					, title_data          = "[]"
					, next_attempt_date   = ""
					, result_url          = ""
					, return_url          = ""
				} ).$results( taskId );

				expect( service.createTask(
					  event         = event
					, args          = args
					, retryInterval = [{ tries=4, interval=CreateTimeSpan( 0, 0, 3, 45 ) }]
				) ).toBe( taskId );
			} );

			it( "should schedule execution in the future when 'runIn' is set", function(){
				var service     = _getService();
				var owner       = CreateUUId();
				var event       = "some.event";
				var args        = { test=CreateUUId(), foobar=[ 1, 2, CreateUUId() ] };
				var taskId      = CreateUUId();
				var runIn       = CreateTimeSpan( 3, 5, 25, 35 );
				var nextRunDate = DateAdd( "s", runIn.getSeconds(), nowish );

				mockTaskDao.$( "insertData" ).$args( {
					  event               = event
					, event_args          = SerializeJson( _addMockRequestState( args ) )
					, admin_owner         = ""
					, web_owner           = owner
					, discard_on_complete = true
					, retry_interval      = "[]"
					, title               = "myresource:export.title"
					, title_data          = '["test","this"]'
					, result_url          = "http://www.mysite.com/download/export/"
					, return_url          = "http://www.mysite.com/download/cancelled/"
					, next_attempt_date   = nextRunDate
				} ).$results( taskId );

				service.$( "runTaskInThread" );

				expect( service.createTask(
					  webOwner          = owner
					, event             = event
					, args              = args
					, runIn             = runIn
					, discardOnComplete = true
					, title             = "myresource:export.title"
					, titleData         = [ "test", "this" ]
					, resultUrl         = "http://www.mysite.com/download/export/"
					, returnUrl         = "http://www.mysite.com/download/cancelled/"
				) ).toBe( taskId );
			} );
		} );

		describe( "markTaskAsRunning()", function(){
			it( "should update status of db record", function(){
				var service = _getService();
				var taskId  = CreateUUId();

				mockTaskDao.$( "updateData", 1 );

				service.markTaskAsRunning( taskId );

				var log = mockTaskDao.$callLog().updateData;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( { id=taskId, data={
					  status              = "running"
					, started_on          = nowish
					, finished_on         = ""
					, progress_percentage = 0
					, log                 = ""
					, next_attempt_date   = ""
				} } );
			} );
		} );

		describe( "completeTask()", function(){
			it( "should update status of db record", function(){
				var service = _getService();
				var taskId = CreateUUId();

				mockTaskDao.$( "updateData", 1 );

				service.$( "getTask" ).$args( taskId ).$results( QueryNew( 'discard_on_complete', 'boolean', [[ false ]] ) );
				service.completeTask( taskId );

				var log = mockTaskDao.$callLog().updateData;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( {
					  id   = taskId
					, data = { status="succeeded", finished_on=nowish }
				} );
			} );

			it( "should discard the task if set to discard on complete", function(){
				var service = _getService();
				var taskId = CreateUUId();

				service.$( "getTask" ).$args( taskId ).$results( QueryNew( 'discard_on_complete', 'boolean', [[ true ]] ) );
				service.$( "discardTask", true );
				mockTaskDao.$( "updateData", 1 );

				service.completeTask( taskId );

				var log = mockTaskDao.$callLog().updateData;
				expect( log.len() ).toBe( 0 );

				log = service.$callLog().discardTask;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( { taskId=taskId } );
			} );
		} );

		describe( "failTask()", function(){
			it( "should update status of db record to failed when no retry attempts defined", function(){
				var service     = _getService();
				var taskId      = CreateUUId();
				var error       = { type="test.error", message="Something went wrong" };
				var nextAttempt = { totalAttempts=1, nextAttemptDate="" };
				var forceRetry  = false;

				mockTaskDao.$( "updateData", 1 );
				service.$( "getNextAttemptInfo" ).$args( taskId, forceRetry ).$results( nextAttempt );

				service.failTask( taskId, error );

				var log = mockTaskDao.$callLog().updateData;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( {
					  id   = taskId
					, data = { status="failed", last_error=SerializeJson( error ), attempt_count=nextAttempt.totalAttempts, finished_on=nowish }
				} );
			} );

			it( "should requeue task when another attempt is due", function(){
				var service     = _getService();
				var taskId      = CreateUUId();
				var error       = { type="test.error", message="Something went wrong" };
				var nextAttempt = { totalAttempts=3, nextAttemptDate=DateAdd( "n", 40, Now() ) };
				var forceRetry  = false;

				mockTaskDao.$( "updateData", 1 );
				service.$( "getNextAttemptInfo" ).$args( taskId, forceRetry ).$results( nextAttempt );
				service.$( "requeueTask" );

				service.failTask( taskId, error );

				var log = mockTaskDao.$callLog().updateData;
				expect( log.len() ).toBe( 0 );

				log = service.$callLog().requeueTask;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( {
					  taskId          = taskId
					, error           = error
					, attemptCount    = nextAttempt.totalAttempts
					, nextAttemptDate = nextAttempt.nextAttemptDate
				} );
			} );

			it( "should requeue task when forceRetry is true, even if no retry attempts defined", function(){
				var service     = _getService();
				var taskId      = CreateUUId();
				var error       = { type="test.error", message="Something went wrong" };
				var nextAttempt = { totalAttempts=0, nextAttemptDate=DateAdd( "n", 1, Now() ) };
				var forceRetry  = true;

				mockTaskDao.$( "updateData", 1 );
				service.$( "getNextAttemptInfo" ).$args( taskId, forceRetry ).$results( nextAttempt );
				service.$( "requeueTask" );

				service.failTask( taskId, error, forceRetry );

				var log = mockTaskDao.$callLog().updateData;
				expect( log.len() ).toBe( 0 );

				log = service.$callLog().requeueTask;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( {
					  taskId          = taskId
					, error           = error
					, attemptCount    = nextAttempt.totalAttempts
					, nextAttemptDate = nextAttempt.nextAttemptDate
				} );
			} );
		} );

		describe( "requeueTask()", function(){
			it( "should update status of db record to requeued", function(){
				var service         = _getService();
				var taskId          = CreateUUId();
				var error           = { type="blah", message=CreateUUId() };
				var attemptCount    = 10;
				var nextAttemptDate = DateAdd( 'n', 40, Now() );

				mockTaskDao.$( "updateData", 1 );

				service.requeueTask(
					  taskId          = taskId
					, error           = error
					, attemptCount    = attemptCount
					, nextAttemptDate = nextAttemptDate
				);

				var log = mockTaskDao.$callLog().updateData;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( {
					  id   = taskId
					, data = { status="requeued", last_error=SerializeJson( error ), attempt_count=attemptCount, next_attempt_date=nextAttemptDate, finished_on=nowish }
				} );
			} );

		} );

		describe( "setProgress()", function(){
			it( "should set the progress percentage against the DB record", function(){
				var service = _getService();
				var taskId = CreateUUId();
				var progress = 84;

				mockTaskDao.$( "updateData", 1 );

				service.setProgress( taskId, progress );

				var log = mockTaskDao.$callLog().updateData;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( {
					  id   = taskId
					, data = { progress_percentage=progress }
				} );
			} );
		} );

		describe( "setResult()", function(){
			it( "should set the task result against the DB record", function(){
				var service = _getService();
				var taskId = CreateUUId();
				var result = { complex=true, random=[ CreateUUId() ] };

				mockTaskDao.$( "updateData", 1 );

				service.setResult( taskId, result );

				var log = mockTaskDao.$callLog().updateData;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( {
					  id   = taskId
					, data = { result=SerializeJson( result ) }
				} );
			} );
		} );


		describe( "setResultUrl()", function(){
			it( "should set the task URL against the DB record", function(){
				var service   = _getService();
				var taskId    = CreateUUId();
				var resultUrl = "http://www.test.this.com/blah=" & taskId;

				mockTaskDao.$( "updateData", 1 );

				service.setResultUrl( taskId, resultUrl );

				var log = mockTaskDao.$callLog().updateData;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( {
					  id   = taskId
					, data = { result_url=resultUrl }
				} );
			} );
		} );

		describe( "getProgress()", function(){
			it( "should return a struct with task ID, status, progress, time taken, time remaining and result from the DB record", function(){
				var service  = _getService();
				var taskId   = CreateUUId();
				var dbResult = QueryNew( 'id,status,progress_percentage,result,log,started_on,finished_on,return_url,result_url', 'varchar,varchar,varchar,varchar,varchar,date,date,varchar,varchar', [[ taskId, "running", 45, "{ test:'this' }", "blah", DateAdd( "s", -234, nowish ), "", "", "" ]] );
				var expected = {
					  id            = dbResult.id
					, status        = dbResult.status
					, progress      = dbResult.progress_percentage
					, log           = dbResult.log
					, result        = DeserializeJson( dbResult.result )
					, timeTaken     = 234
					, timeRemaining = 286
					, resultUrl     = ""
					, returnUrl     = ""
				};

				service.$( "getTask" ).$args( taskId ).$results( dbResult );

				expect( service.getProgress( taskId ) ).toBe( expected );
			} );

			it( "should return an empty struct when the task does not exist", function(){
				var service  = _getService();
				var taskId   = CreateUUId();
				var dbResult = QueryNew( 'id,status,progress_percentage,result' );

				service.$( "getTask" ).$args( taskId ).$results( dbResult );

				expect( service.getProgress( taskId ) ).toBe( {} );
			} );

			it( "should return time taken/remaining as 0 when status is 'pending'", function(){
				var service  = _getService();
				var taskId   = CreateUUId();
				var dbResult = QueryNew( 'id,status,progress_percentage,result,log,started_on,finished_on,return_url,result_url', 'varchar,varchar,varchar,varchar,varchar,date,date,varchar,varchar', [[ taskId, "pending", 0, "", "", "", "", "", "" ]] );
				var expected = {
					  id            = dbResult.id
					, status        = dbResult.status
					, progress      = dbResult.progress_percentage
					, log           = dbResult.log
					, result        = {}
					, timeTaken     = 0
					, timeRemaining = 0
					, resultUrl     = ""
					, returnUrl     = ""
				};

				service.$( "getTask" ).$args( taskId ).$results( dbResult );

				expect( service.getProgress( taskId ) ).toBe( expected );
			} );

			it( "should return time taken calculated from start and finish date when status is 'failed'", function(){
				var service  = _getService();
				var taskId   = CreateUUId();
				var dbResult = QueryNew( 'id,status,progress_percentage,result,log,started_on,finished_on,return_url,result_url', 'varchar,varchar,varchar,varchar,varchar,date,date,varchar,varchar', [[ taskId, "failed", 85, "", "", DateAdd('h',-1,nowish), DateAdd('n',-46,nowish), "", "" ]] );
				var expected = {
					  id            = dbResult.id
					, status        = dbResult.status
					, progress      = dbResult.progress_percentage
					, log           = dbResult.log
					, result        = {}
					, timeTaken     = 840
					, timeRemaining = 0
					, resultUrl     = ""
					, returnUrl     = ""
				};

				service.$( "getTask" ).$args( taskId ).$results( dbResult );

				expect( service.getProgress( taskId ) ).toBe( expected );
			} );
		} );

		describe( "discardTask()", function(){
			it( "should delete the task from the database", function(){
				var service  = _getService();
				var taskId   = CreateUUId();

				mockTaskDao.$( "deleteData", 1 );

				expect( service.discardTask( taskId ) ).toBe( true );

				var log = mockTaskDao.$callLog().deleteData;

				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( { id=taskId } );
			} );
		} );

		describe( "getNextAttemptInfo()", function(){
			it( "should should return a struct with totalAttempts set to previous attempts+1 and an empty string for next date, when task has no retry attempts configured", function(){
				var service = _getService();
				var taskId  = CreateUUId();
				var task    = QueryNew( "retry_interval,attempt_count", "varchar,int", [ [ "[]", 0 ] ] );

				service.$( "getTask" ).$args( taskId ).$results( task );

				expect( service.getNextAttemptInfo( taskId ) ).toBe( { totalAttempts=1, nextAttemptDate="" } );
			} );

			it( "should return an empty struct when the task is all out of retries", function(){
				var service       = _getService();
				var taskId        = CreateUUId();
				var retryInterval = [ { tries=3,interval=5 }, { tries=2, interval=30 } ];
				var task          = QueryNew( "retry_interval,attempt_count", "varchar,int", [ [ SerializeJson( retryInterval ), 4 ] ] );

				service.$( "getTask" ).$args( taskId ).$results( task );

				expect( service.getNextAttemptInfo( taskId ) ).toBe( { totalAttempts=5, nextAttemptDate="" } );
			} );

			it( "should return a struct with 'nextAttemptDate' calculated from current date + next retry interval + 'totalAttempts' from database attempt count (plus one)", function(){
				var service       = _getService();
				var taskId        = CreateUUId();
				var retryInterval = [ { tries=3,interval=CreateTimeSpan( 0, 0, 5, 0 ).getSeconds() }, { tries=2, interval=CreateTimeSpan( 0, 0, 30, 0 ).getSeconds() } ];
				var task          = QueryNew( "retry_interval,attempt_count", "varchar,int", [ [ SerializeJson( retryInterval ), 3 ] ] );

				service.$( "getTask" ).$args( taskId ).$results( task );

				expect( service.getNextAttemptInfo( taskId ) ).toBe( {
					  totalAttempts   = 4
					, nextAttemptDate = DateTimeFormat( DateAdd( "n", 30, nowish ), "yyyy-mm-dd HH:nn:ss" )
				} );
			} );
		} );

		describe( "getTaskRunnerUrl()", function(){
			it( "should build a /taskmanager/runadhoctask/ URL for the given task ID and site context", function(){
				var service     = _getService();
				var taskId      = CreateUUId();
				var siteContext = CreateUUId();
				var domain      = "my.#CreateUUId()#.com";
				var mockUrl     = CreateUUId();

				mockRequestContext.$( "getSite" ).$results( {} );
				mockRequestContext.$( "setSite" );
				mockSiteService.$( "getSite", {} );
				mockRequestContext.$( "buildLink" ).$args( linkto="taskmanager.runadhoctask", queryString="taskId=#taskId#" ).$results( mockUrl );

				expect( service.getTaskRunnerUrl( taskId, siteContext) ).toBe( mockUrl );
			} );
		} );
	}


// private helpers
	private any function _getService() {
		mockTaskDao         = CreateStub();
		mockColdbox         = CreateStub();
		mockRequestContext  = CreateStub();
		mockTaskScheduler   = CreateStub();
		mockSiteService     = CreateStub();
		mockLogboxLogger    = CreateStub();
		mockThreadUtil      = CreateStub();
		mockExecutor        = CreateStub();
		nowish              = DateAdd( 'd', 1, Now() );

		var service = CreateMock( object=new preside.system.services.taskmanager.AdHocTaskManagerService(
			  taskScheduler        = mockTaskScheduler
			, siteService          = mockSiteService
			, logger               = mockLogBoxLogger
			, threadUtil           = mockThreadUtil
			, executor             = mockExecutor
		) );

		mockRequestContext.$( "setUseQueryCache" );
		mockRequestContext.$( "getSiteId", "mock-site-id" );
		mockRequestContext.$( "getLanguage", "mock-language" );

		service.$( "$getPresideObject" ).$args( "taskmanager_adhoc_task" ).$results( mockTaskDao );
		service.$( "$getColdbox", mockColdbox );
		service.$( "$getRequestContext", mockRequestContext );
		service.$( "$isFeatureEnabled" ).$args( "sslInternalHttpCalls" ).$results( true );
		service.$( "_now", nowish );
		service.$( "_setRequestState" );

		return service;
	}

	private void function _mockGetTask( required string taskId, required query result ) {
		mockTaskDao.$( "selectData" ).$args( id=arguments.taskId ).$results( arguments.result );
	}

	private any function _mockProgress( required any service, required string taskId ) {
		var dummyObj    = CreateStub();
		    dummyObj.id = CreateUUId();

		service.$( "_getTaskProgressReporter" ).$args( arguments.taskId ).$results( dummyObj );

		return dummyObj;
	}
	private any function _mockLogger( required any service, required string taskId ) {
		var dummyObj    = CreateStub();
		    dummyObj.id = CreateUUId();

		service.$( "_getTaskLogger" ).$args( arguments.taskId ).$results( dummyObj );

		return dummyObj;
	}

	private struct function _addMockRequestState( struct args ){
		args.__requestState = {
			  site     = "mock-site-id"
			, language = "mock-language"
		};

		return args;
	}
}