/**
 * @presideService true
 * @singleton      true
 *
 */
component extends="AbstractHeartBeat" {

	/**
	 * @adhocTaskmanagerService.inject adhocTaskmanagerService
	 * @threadUtil.inject              threadUtil
	 *
	 */
	public function init( required any adhocTaskmanagerService, required any threadUtil ){
		super.init(
			  threadName   = "Preside Heartbeat: Adhoc Tasks"
			, intervalInMs = 1000
			, threadUtil   = arguments.threadUtil
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

	public void function startInNewRequest() {
		var startUrl = _buildInternalLink( linkTo="taskmanager.runtasks.startAdhocTaskManagerHeartbeat" );

		thread name=CreateUUId() startUrl=startUrl {
			var attemptLimit = 10;
			var attempt      = 1;
			var success      = false;

			do {
				try {
					sleep( 5000 );
					http method="post" url=startUrl timeout=10 throwonerror=true;
					success = true;
				} catch( any e ) {
					$raiseError( e );
					$systemOutput( "Failed to start adhoc taskmanager heartbeat. Retrying...(attempt #attempt#)");
				}
			} while ( !success && ++attempt <= 10 );
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