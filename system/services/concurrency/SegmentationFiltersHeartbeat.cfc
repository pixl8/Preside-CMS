/**
 * @presideService true
 * @singleton      true
 */
component extends="AbstractHeartBeat" {

	/**
	 * @scheduledThreadpoolExecutor.inject presideScheduledThreadpoolExecutor
	 * @hostname.inject                    coldbox:setting:heartbeats.taskmanager.hostname
	 * @rulesEngineFilterService.inject    rulesEngineFilterService
	 *
	 */
	public function init(
		  required any    scheduledThreadpoolExecutor
		, required string hostname
		, required any    rulesEngineFilterService
	){
		super.init(
			  threadName                  = "Preside Heartbeat: Segmentation Filter calculation"
			, intervalInMs                = ( 1000 * 60 * 10 ) // 10 mins
			, scheduledThreadpoolExecutor = arguments.scheduledThreadpoolExecutor
			, feature                     = "segmentationFiltersHeartbeat"
			, hostname                    = arguments.hostname
		);

		_setRulesEngineFilterService( arguments.rulesEngineFilterService );

		return this;
	}

	// PUBLIC API METHODS
	public void function $run() {
		if ( $isFeatureEnabled( "dataExport" ) ) {
			try {
				_getRulesEngineFilterService().recalculateAllSegmentationFilters();
			} catch( any e ) {
				$raiseError( e );
			}
		}
	}

// GETTERS AND SETTERS
	private any function _getRulesEngineFilterService() {
	    return _rulesEngineFilterService;
	}
	private void function _setRulesEngineFilterService( required any rulesEngineFilterService ) {
	    _rulesEngineFilterService = arguments.rulesEngineFilterService;
	}
}