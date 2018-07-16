/**
 *
 * @presideService true
 * @singleton      true
 *
 */
component extends="AbstractHeartBeat" {

	/**
	 * @taskmanagerService.inject taskmanagerService
	 *
	 */
	public function init( required any taskmanagerService ){
		super.init(
			  threadName   = "Preside Taskmanager Heartbeat"
			, intervalInMs = 1000
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
	}

// GETTERS AND SETTERS
	private any function _getTaskmanagerService() {
		return _taskmanagerService;
	}
	private void function _setTaskmanagerService( required any taskmanagerService ) {
		_taskmanagerService = arguments.taskmanagerService;
	}
}
