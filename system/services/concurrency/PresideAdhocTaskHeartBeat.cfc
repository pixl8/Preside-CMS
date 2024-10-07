/**
 * @presideService true
 * @singleton      true
 *
 */
component extends="AbstractHeartBeat" {

	/**
	 * @adhocTaskmanagerService.inject     adhocTaskmanagerService
	 * @scheduledThreadpoolExecutor.inject presideScheduledThreadpoolExecutor
	 * @hostname.inject                    coldbox:setting:heartbeats.adhoctask.hostname
	 */
	public function init(
		  required any    adhocTaskmanagerService
		, required any    scheduledThreadpoolExecutor
		, required string hostname
	){
		super.init(
			  threadName                  = "Preside Heartbeat: Adhoc Tasks"
			, intervalInMs                = 1000
			, scheduledThreadpoolExecutor = arguments.scheduledThreadpoolExecutor
			, feature                     = "adhocTaskHeartBeat"
			, hostname                    = arguments.hostname
		);

		_setAdhocTaskmanagerService( arguments.adhocTaskmanagerService );

		return this;
	}

	// PUBLIC API METHODS
	public void function $run() {
		try {
			_getAdhocTaskmanagerService().runScheduledTasks();
		} catch( any e ) {
			$raiseError( e );
		}

		if ( _doCleanupRun() ) {
			try {
				_getAdhocTaskmanagerService().processStaleLockedTasks();
			} catch( any e ) {
				$raiseError( e );
			}
			try {
				_getAdhocTaskmanagerService().failInactiveRunningTasks();
			} catch( any e ) {
				$raiseError( e );
			}
		}
	}

// PRIVATE HELPERS
	private function _doCleanupRun() {
		if ( !StructKeyExists( variables, "lastCleanupRun" ) || DateDiff( 'n', variables.lastCleanupRun, Now() ) >= 5 ) {
			variables.lastCleanupRun = Now();
			return true;
		}

		return false;
	}


// GETTERS AND SETTERS
	private any function _getAdhocTaskmanagerService() {
		return _taskmanagerService;
	}
	private void function _setAdhocTaskmanagerService( required any adhocTaskmanagerService ) {
		_taskmanagerService = arguments.adhocTaskmanagerService;
	}
}