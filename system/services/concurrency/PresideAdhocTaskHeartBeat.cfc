/**
 * @presideService true
 * @singleton      true
 *
 */
component extends="AbstractHeartBeat" {

	/**
	 * @adhocTaskmanagerService.inject     adhocTaskmanagerService
	 * @scheduledThreadpoolExecutor.inject presideScheduledThreadpoolExecutor
	 *
	 */
	public function init( required any adhocTaskmanagerService, required any scheduledThreadpoolExecutor ){
		super.init(
			  threadName                  = "Preside Heartbeat: Adhoc Tasks"
			, intervalInMs                = 1000
			, scheduledThreadpoolExecutor = arguments.scheduledThreadpoolExecutor
			, feature                     = "adhocTaskHeartBeat"
		);

		_setAdhocTaskmanagerService( arguments.adhocTaskmanagerService );

		return this;
	}

	// PUBLIC API METHODS
	public void function run() {
		try {
			_getAdhocTaskmanagerService().runScheduledTasks();
		} catch( any e ) {
			$raiseError( e );
		}

		setLastRun();
	}


// GETTERS AND SETTERS
	private any function _getAdhocTaskmanagerService() {
		return _taskmanagerService;
	}
	private void function _setAdhocTaskmanagerService( required any adhocTaskmanagerService ) {
		_taskmanagerService = arguments.adhocTaskmanagerService;
	}
}