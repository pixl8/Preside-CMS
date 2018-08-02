/**
 * @presideService true
 * @singleton      true
 *
 */
component extends="AbstractHeartBeat" {

	/**
	 * @healthCheckService.inject healthCheckService
	 * @threadUtil.inject         threadUtil
	 *
	 */
	public function init(
		  required any     healthCheckService
		, required any     threadUtil
		,          string  threadName     = "Preside Service Healthcheck Heartbeat"
	){
		super.init(
			  threadName   = arguments.threadName
			, threadUtil   = arguments.threadUtil
			, intervalInMs = 30000
		);

		_setHealthcheckService( arguments.healthCheckService );

		return this;
	}

	// PUBLIC API METHODS
	public void function run() {
		try {
			var healthCheckService = _getHealthCheckService();
			var services           = healthCheckService.listRegisteredServices();

			if ( !services.len() ) {
				super.shutdown();
			}

			for( var serviceId in services ) {
				if ( !healthCheckService.checkService( serviceId ) ) {
					$systemOutput( "System healthcheck is reporting that the service, [#serviceId#], is currently DOWN." );
				}

				if ( $isInterrupted() ) {
					break;
				}
			}
		} catch( any e ) {
			$raiseError( e );
		}
	}

	public void function startInNewRequest() {
		var startUrl = $getRequestContext().buildLink( linkTo="taskmanager.runtasks.startHealthCheckHeartbeat" );

		thread name=CreateUUId() startUrl=startUrl {
			try {
				sleep( 1000 );
				http method="post" url=startUrl timeout=2 throwonerror=true {}
			} catch( any e ) {
				$raiseError( e );
			}
		}
	}

// GETTERS AND SETTERS
	private any function _getHealthCheckService() {
		return _healthCheckService;
	}
	private void function _setHealthCheckService( required any healthCheckService ) {
		_healthCheckService = arguments.healthCheckService;
	}
}