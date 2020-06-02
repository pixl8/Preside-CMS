/**
 *
 * @presideService true
 * @singleton      true
 *
 */
component extends="AbstractHeartBeat" {

	/**
	 * @taskmanagerService.inject          taskmanagerService
	 * @scheduledThreadpoolExecutor.inject presideScheduledThreadpoolExecutor
	 * @hostname.inject                    coldbox:setting:heartbeats.taskmanager.hostname
	 *
	 */
	public function init(
		  required any    taskmanagerService
		, required any    scheduledThreadpoolExecutor
		, required string hostname
	){
		super.init(
			  threadName                  = "Preside Heartbeat: Scheduled Tasks"
			, intervalInMs                = 1000
			, scheduledThreadpoolExecutor = arguments.scheduledThreadpoolExecutor
			, feature                     = "taskmanagerHeartBeat"
			, hostname                    = arguments.hostname
		);

		_setTaskmanagerService( arguments.taskmanagerService );

		return this;
	}

	// PUBLIC API METHODS
	public void function $run() {
		try {
			var result = _getTaskmanagerService().runScheduledTasks();
			_getTaskmanagerService().cleanupNoLongerRunningTasks();

			if ( Len( Trim( result.error ?: "" ) ) ) {
				throw( type="preside.taskmanager.heartbeat.error", message=result.error );
			}
		} catch( any e ) {
			$raiseError( e );
		}
	}


// GETTERS AND SETTERS
	private any function _getTaskmanagerService() {
		return _taskmanagerService;
	}
	private void function _setTaskmanagerService( required any taskmanagerService ) {
		_taskmanagerService = arguments.taskmanagerService;
	}
}
