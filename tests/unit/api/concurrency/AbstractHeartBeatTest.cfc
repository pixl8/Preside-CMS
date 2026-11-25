component extends="testbox.system.BaseSpec" {

	function run(){

		describe( "run()", function(){

			it( "should run the heartbeat's $run() method", function(){
				var heartbeat = _getHeartbeat();

				heartbeat.run();

				expect( heartbeat.getRunCount() ).toBe( 1 );
			} );

			it( "should not start a second run while one is already in progress", function(){
				var heartbeat = _getHeartbeat();
				var nested    = { attempted=false };

				heartbeat.setRunBehaviour( function(){
					if ( !nested.attempted ) {
						nested.attempted = true;
						heartbeat.run();
					}
				} );
				heartbeat.run();

				expect( heartbeat.getRunCount() ).toBe( 1 );
			} );

			it( "should allow the next run when the previous run threw an error", function(){
				var heartbeat = _getHeartbeat();
				var errorType = "";

				heartbeat.setRunBehaviour( function(){
					throw( type="test.run.error", message="Simulated failure during a run" );
				} );

				try {
					heartbeat.run();
				} catch ( any e ) {
					errorType = e.type;
				}

				heartbeat.setRunBehaviour( function(){} );
				heartbeat.run();

				expect( errorType ).toBe( "test.run.error" );
				expect( heartbeat.getRunCount() ).toBe( 2 );
			} );

			it( "should not throw, and should allow the next run, when the thread was interrupted during the run", function(){
				var heartbeat    = _getHeartbeat();
				var errorMessage = "";

				heartbeat.setRunBehaviour( function(){
					_interruptCurrentThread();
				} );

				try {
					heartbeat.run();
				} catch ( any e ) {
					errorMessage = e.message;
				} finally {
					_clearInterruptedFlag();
				}

				heartbeat.setRunBehaviour( function(){} );
				heartbeat.run();

				expect( errorMessage ).toBe( "" );
				expect( heartbeat.getRunCount() ).toBe( 2 );
			} );

		} );

		describe( "start()", function(){

			it( "should schedule the heartbeat when it has never been started", function(){
				var executor  = _getExecutor();
				var heartbeat = _getHeartbeat( executor );

				heartbeat.start();

				expect( executor.$count( "scheduleAtFixedRate" ) ).toBe( 1 );
			} );

			it( "should schedule the heartbeat after a run was interrupted and the heartbeat stopped", function(){
				var executor  = _getExecutor();
				var heartbeat = _getHeartbeat( executor );

				heartbeat.setRunBehaviour( function(){
					_interruptCurrentThread();
				} );

				try {
					heartbeat.run();
				} catch ( any e ) {
					var ignoredError = e;
				} finally {
					_clearInterruptedFlag();
				}

				heartbeat.stop( waitForCurrentRun=false );
				heartbeat.start();

				expect( executor.$count( "scheduleAtFixedRate" ) ).toBe( 1 );
			} );

		} );

		describe( "stop()", function(){

			it( "should cancel the scheduled task", function(){
				var executor  = _getExecutor();
				var heartbeat = _getHeartbeat( executor );

				heartbeat.stop( waitForCurrentRun=false );

				expect( executor.$count( "cancelTask" ) ).toBe( 1 );
			} );

			it( "should prevent runs that arrive after the stop from running", function(){
				var heartbeat = _getHeartbeat();

				heartbeat.stop( waitForCurrentRun=false );
				heartbeat.run();

				expect( heartbeat.getRunCount() ).toBe( 0 );
			} );

			it( "should let runs happen again once the heartbeat has been started again", function(){
				var heartbeat = _getHeartbeat();

				heartbeat.stop( waitForCurrentRun=false );
				heartbeat.start();
				heartbeat.run();

				expect( heartbeat.getRunCount() ).toBe( 1 );
			} );

		} );

	}

// PRIVATE HELPERS
	private any function _getHeartbeat( any executor=_getExecutor() ) {
		var heartbeat = new resources.heartbeat.TestHeartBeat(
			  threadName                  = "Unit test heartbeat"
			, intervalInMs                = 1000
			, scheduledThreadpoolExecutor = arguments.executor
			, hostname                    = "localhost"
		);

		return heartbeat;
	}

	private any function _getExecutor() {
		var mockBox  = getMockBox();
		var executor = mockBox.createStub();
		var future   = mockBox.createStub();

		future.$( "isDone", false );
		future.$( "isCancelled", false );

		executor.$( "isStarted", true );
		executor.$( "start" );
		executor.$( "cancelTask" );
		executor.$( "getObjectFactory", { MILLISECONDS="milliseconds" } );
		executor.$( "scheduleAtFixedRate", future );

		return executor;
	}

	private void function _interruptCurrentThread() {
		CreateObject( "java", "java.lang.Thread" ).currentThread().interrupt();
	}

	private void function _clearInterruptedFlag() {
		CreateObject( "java", "java.lang.Thread" ).interrupted();
	}

}
