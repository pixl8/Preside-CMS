component extends="testbox.system.BaseSpec" {

	public void function run() {
		describe( "runTask()", function(){
			it( "should call the handler defined for the task, passing additional args set", function(){
				var service = _getService();
				var taskId  = CreateUUId();
				var event   = "some.handler.action";
				var args    = { test=CreateUUId(), fubar=123 };
				var taskDef = QueryNew( 'event,event_args', 'varchar,varchar', [ [ event, SerializeJson( args ) ] ] );

				_mockGetTask( taskId, taskDef );
				_mockRunEvent( event, { args=args } );

				service.runTask( taskId );

				var log = mockColdbox.$callLog().runEvent;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( {
					  event          = event
					, eventArguments = { args=args }
					, private        = true
					, prepostExempt  = true
				} );
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

	private void function _mockRunEvent( required string event, struct args={}, any result ) {
		mockColdbox.$( "runEvent" ).$args(
			  event          = arguments.event
			, eventArguments = arguments.args
			, private        = true
			, prepostExempt  = true
		).$results( arguments.result ?: NullValue() );
	}
}