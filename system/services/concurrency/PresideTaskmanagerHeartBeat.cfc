/**
 *
 * @presideService true
 * @singleton      true
 *
 */
component extends="AbstractHeartBeat" {

	/**
	 * @taskmanagerService.inject taskmanagerService
	 * @threadUtil.inject         threadUtil
	 *
	 */
	public function init( required any taskmanagerService, required any threadUtil ){
		super.init(
			  threadName   = "Preside Heartbeat: Scheduled Tasks"
			, intervalInMs = 1000
			, threadUtil   = arguments.threadUtil
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

	public void function startInNewRequest() {
		var startUrl = $getRequestContext().buildLink( linkTo="taskmanager.runtasks.startTaskManagerHeartbeat" );

		thread name=CreateUUId() startUrl=startUrl {
			var attemptLimit = 10;
			var attempt      = 1;
			var success      = false;

			do {
				try {
					sleep( 1000 );
					http method="post" url=startUrl timeout=2 throwonerror=true;
					success = true;
				} catch( any e ) {
					$raiseError( e );
					$systemOutput( "Failed to start taskmanager heartbeat. Retrying...(attempt #attempt#)");
				}
			} while ( !success && ++attempt <= 10 );
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
