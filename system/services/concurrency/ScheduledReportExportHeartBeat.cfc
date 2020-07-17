/**
 * @presideService true
 * @singleton      true
 */
component extends="AbstractHeartBeat" {

	/**
	 * @scheduledThreadpoolExecutor.inject presideScheduledThreadpoolExecutor
	 * @hostname.inject                    coldbox:setting:heartbeats.taskmanager.hostname
	 * @scheduledReportService.inject      ScheduledReportService
	 *
	 */
	public function init(
		  required any    scheduledThreadpoolExecutor
		, required string hostname
		, required any    scheduledReportService
	){
		super.init(
			  threadName                  = "Preside Heartbeat: Scheduled Report Export"
			, intervalInMs                = 1000
			, scheduledThreadpoolExecutor = arguments.scheduledThreadpoolExecutor
			, feature                     = "scheduledReportExportHeartBeat"
			, hostname                    = arguments.hostname
		);

		_setScheduledReportService( arguments.scheduledReportService );

		return this;
	}

	// PUBLIC API METHODS
	public void function $run() {
		if ( $isFeatureEnabled( "scheduledReportExport" ) ) {
			try {
				_getScheduledReportService().sendScheduledReports();
			} catch( any e ) {
				$raiseError( e );
			}
		}
	}

// GETTERS AND SETTERS
	private any function _getScheduledReportService() {
		return _scheduledReportService;
	}
	private void function _setScheduledReportService( required any scheduledReportService ) {
		_scheduledReportService = arguments.scheduledReportService;
	}
}