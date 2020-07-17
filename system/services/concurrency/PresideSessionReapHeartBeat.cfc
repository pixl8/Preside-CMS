/**
 * @presideService true
 * @singleton      true
 *
 */
component extends="AbstractHeartBeat" {

	/**
	 * @presideSessionManagementService.inject presideSessionManagementService
	 * @scheduledThreadpoolExecutor.inject     presideScheduledThreadpoolExecutor
	 * @hostname.inject                        coldbox:setting:heartbeats.sessionReap.hostname
	 *
	 */
	public function init(
		  required any    scheduledThreadpoolExecutor
		, required any    presideSessionManagementService
		, required string hostname
		,          string threadName = "Preside Session Manager Reap Heartbeat"
	){
		_setPresideSessionManagementService( arguments.presideSessionManagementService );

		super.init(
			  threadName                  = arguments.threadName
			, scheduledThreadpoolExecutor = arguments.scheduledThreadpoolExecutor
			, hostname                    = arguments.hostname
			, feature                     = "presideSessionManagement"
			, intervalInMs                = ( 1000 * 300 ) // 5 minutes
		);

		return this;
	}

	// PUBLIC API METHODS
	public void function $run() {
		try {
			if ( $isInterrupted() ) {
				return;
			}

			_getPresideSessionManagementService().reap();
		} catch( any e ) {
			$raiseError( e );
		}
	}

// GETTERS AND SETTERS
	private any function _getPresideSessionManagementService() {
	    return _presideSessionManagementService;
	}
	private void function _setPresideSessionManagementService( required any presideSessionManagementService ) {
	    _presideSessionManagementService = arguments.presideSessionManagementService;
	}
}