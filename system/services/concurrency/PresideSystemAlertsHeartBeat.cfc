/**
 * @presideService true
 * @singleton      true
 *
 */
component extends="AbstractHeartBeat" {

	/**
	 * @systemAlertsService.inject         systemAlertsService
	 * @scheduledThreadpoolExecutor.inject presideScheduledThreadpoolExecutor
	 * @hostname.inject                    coldbox:setting:heartbeats.systemalerts.hostname
	 */
	public function init(
		  required any    systemAlertsService
		, required any    scheduledThreadpoolExecutor
		, required string hostname
	){
		super.init(
			  threadName                  = "Preside Heartbeat: SystemAlerts"
			, intervalInMs                = 1000 * 60 // 1 minute
			, scheduledThreadpoolExecutor = arguments.scheduledThreadpoolExecutor
			, feature                     = "systemAlertsHeartBeat"
			, hostname                    = arguments.hostname
		);

		_setSystemAlertsService( arguments.systemAlertsService );

		return this;
	}

	// PUBLIC API METHODS
	public void function $run() {
		try {
			_getSystemAlertsService().runScheduledChecks();
		} catch( any e ) {
			$raiseError( e );
		}
	}


// GETTERS AND SETTERS
	private any function _getSystemAlertsService() {
		return _systemAlertsService;
	}
	private void function _setSystemAlertsService( required any systemAlertsService ) {
		_systemAlertsService = arguments.systemAlertsService;
	}
}