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
	 *
	 */
	public function init( required any taskmanagerService, required any scheduledThreadpoolExecutor ){
		super.init(
			  threadName                  = "Preside Heartbeat: Scheduled Tasks"
			, intervalInMs                = 1000
			, scheduledThreadpoolExecutor = arguments.scheduledThreadpoolExecutor
			, feature                     = "taskmanagerHeartBeat"
		);

		_setTaskmanagerService( arguments.taskmanagerService );

		return this;
	}

	// PUBLIC API METHODS
	public void function run() {
		try {
			var result = _getTaskmanagerService().runScheduledTasks();
			_getTaskmanagerService().cleanupNoLongerRunningTasks();

			if ( Len( Trim( result.error ?: "" ) ) ) {
				throw( type="preside.taskmanager.heartbeat.error", message=result.error );
			}
		} catch( any e ) {
			$raiseError( e );
		}

		setLastRun();
	}


// GETTERS AND SETTERS
	private any function _getTaskmanagerService() {
		return _taskmanagerService;
	}
	private void function _setTaskmanagerService( required any taskmanagerService ) {
		_taskmanagerService = arguments.taskmanagerService;
	}
}
