/**
 * @presideService true
 * @singleton      true
 */
component extends="AbstractHeartBeat" {

	/**
	 * @scheduledThreadpoolExecutor.inject presideScheduledThreadpoolExecutor
	 * @hostname.inject                    coldbox:setting:heartbeats.taskmanager.hostname
	 * @scheduledExportService.inject      ScheduledExportService
	 *
	 */
	public function init(
		  required any    scheduledThreadpoolExecutor
		, required string hostname
		, required any    scheduledExportService
	){
		super.init(
			  threadName                  = "Preside Heartbeat: Scheduled Saved Export"
			, intervalInMs                = 1000
			, scheduledThreadpoolExecutor = arguments.scheduledThreadpoolExecutor
			, feature                     = "scheduledExportHeartBeat"
			, hostname                    = arguments.hostname
		);

		_setScheduledExportService( arguments.scheduledExportService );

		return this;
	}

	// PUBLIC API METHODS
	public void function $run() {
		if ( $isFeatureEnabled( "dataExport" ) ) {
			try {
				_getScheduledExportService().sendScheduledExports();
			} catch( any e ) {
				$raiseError( e );
			}
		}
	}

// GETTERS AND SETTERS
	private any function _getScheduledExportService() {
		return _scheduledExportService;
	}
	private void function _setScheduledExportService( required any scheduledExportService ) {
		_scheduledExportService = arguments.scheduledExportService;
	}
}