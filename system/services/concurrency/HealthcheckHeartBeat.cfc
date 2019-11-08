/**
 * @presideService true
 * @singleton      true
 *
 */
component extends="AbstractHeartBeat" {

	/**
	 * @healthCheckService.inject          healthCheckService
	 * @scheduledThreadpoolExecutor.inject presideScheduledThreadpoolExecutor
	 * @hostname.inject                    coldbox:setting:heartbeats.healthcheck.hostname
	 *
	 */
	public function init(
		  required any     healthCheckService
		, required any     scheduledThreadpoolExecutor
		, required string  serviceId
		, required numeric intervalInMs
		, required string  hostname
		,          string  threadName     = "Preside Service Healthcheck: #arguments.serviceId#"
	){
		super.init(
			  threadName                  = arguments.threadName
			, scheduledThreadpoolExecutor = arguments.scheduledThreadpoolExecutor
			, intervalInMs                = arguments.intervalInMs
			, hostname                    = arguments.hostname
			, feature                     = "healthchecks"
		);

		_setHealthcheckService( arguments.healthCheckService );
		_setServiceId( arguments.serviceId );

		return this;
	}

	// PUBLIC API METHODS
	public void function $run() {
		try {
			if ( $isInterrupted() ) {
				return;
			}

			if ( !_getHealthCheckService().checkService( _getServiceId() ) ) {
				$systemOutput( "System healthcheck is reporting that the service, [#serviceId#], is currently DOWN." );
			}
		} catch( any e ) {
			$raiseError( e );
		}
	}

// GETTERS AND SETTERS
	private any function _getHealthCheckService() {
		return _healthCheckService;
	}
	private void function _setHealthCheckService( required any healthCheckService ) {
		_healthCheckService = arguments.healthCheckService;
	}

	private string function _getServiceId() {
		return _serviceId;
	}
	private void function _setServiceId( required string serviceId ) {
		_serviceId = arguments.serviceId;
	}
}