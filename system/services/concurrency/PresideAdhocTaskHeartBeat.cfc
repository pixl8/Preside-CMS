/**
 * @presideService true
 * @singleton      true
 *
 */
component extends="AbstractHeartBeat" {

	/**
	 * @adhocTaskmanagerService.inject adhocTaskmanagerService
	 *
	 */
	public function init( required any adhocTaskmanagerService ){
		super.init(
			  threadName   = "Preside Adhoc Task Heartbeat"
			, intervalInMs = 1000
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
	}

// GETTERS AND SETTERS
	private any function _getAdhocTaskmanagerService() {
		return _taskmanagerService;
	}
	private void function _setAdhocTaskmanagerService( required any adhocTaskmanagerService ) {
		_taskmanagerService = arguments.adhocTaskmanagerService;
	}
}