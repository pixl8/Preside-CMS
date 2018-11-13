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
		, required string  serviceId
		, required numeric intervalInMs
		,          string  threadName     = "Preside Service Healthcheck: #arguments.serviceId#"
	){
		super.init(
			  threadName   = arguments.threadName
			, threadUtil   = arguments.threadUtil
			, intervalInMs = arguments.intervalInMs
		);

		_setHealthcheckService( arguments.healthCheckService );
		_setServiceId( arguments.serviceId );

		return this;
	}

	// PUBLIC API METHODS
	public void function run() {
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

	public void function startInNewRequest() {
		var startUrl = $getRequestContext().buildLink( linkTo="taskmanager.runtasks.startHealthCheckHeartbeat" );

		thread name=CreateUUId() startUrl=startUrl {
			do {
				try {
					sleep( 10000 );
					http method="post" url=startUrl timeout=10 throwonerror=true {
						httpparam name="serviceId" type="formfield" value=_getServiceId();
					}
					success = true;
				} catch( any e ) {
					$raiseError( e );
					$systemOutput( "Failed to start healthcheck heartbeat. Retrying...(attempt #attempt#)");
				}
			} while ( !success && ++attempt <= 10 );
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