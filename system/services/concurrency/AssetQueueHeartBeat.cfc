/**
 * @presideService true
 * @singleton      true
 *
 */
component extends="AbstractHeartBeat" {

	/**
	 * @threadUtil.inject        threadUtil
	 * @assetQueueService.inject assetQueueService
	 *
	 */
	public function init(
		  required any     threadUtil
		, required any     assetQueueService
		,          numeric instanceNumber = 1
		,          string  threadName     = "Preside Asset Queue Processor #arguments.instanceNumber#"
	){
		super.init(
			  threadName   = arguments.threadName
			, threadUtil   = arguments.threadUtil
			, intervalInMs = 2000
			, feature      = "assetQueueHeartBeat"
		);

		_setAssetQueueService( arguments.assetQueueService );
		_setInstanceNumber( arguments.instanceNumber );

		return this;
	}

	// PUBLIC API METHODS
	public void function run() {
		var queueService = _getAssetQueueService();

		try {
			queueService.processQueue();
		} catch( any e ) {
			$raiseError( e );
		}
	}

	public void function startInNewRequest() {
		var startUrl = _buildInternalLink( linkTo="taskmanager.runtasks.startAssetQueueHeartbeat" );

		thread name=CreateUUId() startUrl=startUrl {
			var attemptLimit = 10;
			var attempt      = 1;
			var success      = false;

			do {
				try {
					sleep( 20000 + ( 100 * _getInstanceNumber() ) );
					http method="post" url=startUrl timeout=10 throwonerror=true {
						httpparam type="formfield" name="instanceNumber" value=_getInstanceNumber();
					}
					success = true;
				} catch( any e ) {
					$raiseError( e );
					$systemOutput( "Failed to start asset queue heartbeat at #startUrl#. Retrying...(attempt #attempt#)");
				}
			} while ( !success && ++attempt <= 10 );
		}
	}

// GETTERS AND SETTERS
	private any function _getAssetQueueService() {
	    return _assetQueueService;
	}
	private void function _setAssetQueueService( required any assetQueueService ) {
	    _assetQueueService = arguments.assetQueueService;
	}

	private any function _getInstanceNumber() {
		return _instanceNumber;
	}
	private void function _setInstanceNumber( required any instanceNumber ) {
		_instanceNumber = arguments.instanceNumber;
	}
}