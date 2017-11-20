component extends="testbox.system.BaseSpec" {

	public void function run() {
		describe( "runTask()", function(){
			it( "should call the handler defined for the task, passing additional args set, a special logger and special progress object for the task", function(){
				var service = _getService();
				var taskId  = CreateUUId();
				var event   = "some.handler.action";
				var args    = { test=CreateUUId(), fubar=123 };
				var taskDef = QueryNew( 'event,event_args', 'varchar,varchar', [ [ event, SerializeJson( args ) ] ] );

				_mockGetTask( taskId, taskDef );
				mockColdbox.$( "runEvent" );
				var mockProgress = _mockProgress( service, taskId );
				var mockLogger   = _mockLogger( service, taskId );

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

			it( "should return false and log error when an error is thrown during execution of the handler action", function(){
				var service = _getService();
				var taskId  = CreateUUId();
				var event   = "some.handler.action";
				var args    = { test=CreateUUId(), fubar=123 };
				var taskDef = QueryNew( 'event,event_args', 'varchar,varchar', [ [ event, SerializeJson( args ) ] ] );

				_mockGetTask( taskId, taskDef );
				var mockProgress = _mockProgress( service, taskId );
				var mockLogger   = _mockLogger( service, taskId );

				mockColdbox.$( "runEvent" ).$throws( type="SomeError", message="boo :(" );
				service.$( "$raiseError" )

				expect( service.runTask( taskId ) ).toBe( false );

				var log = service.$callLog().$raiseError;
				expect( log.len() ).toBe( 1 );
				expect( log[1].error.type    ?: "" ).toBe( "SomeError" );
				expect( log[1].error.message ?: "" ).toBe( "boo :(" );
			} );
		} );
	}


// private helpers
	private any function _getService() {
		var service = new preside.system.services.taskmanager.AdHocTaskManagerService();

		service = CreateMock( object=service );

		mockTaskDao = CreateStub();
		mockColdbox = CreateStub();

		service.$( "$getPresideObject" ).$args( "taskmanager_adhoc_task" ).$results( mockTaskDao );
		service.$( "$getColdbox", mockColdbox );

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
}