/**
 * @presideService true
 * @singleton      true
 *
 */
component extends="AbstractHeartBeat" {

	/**
	 * @emailMassSendingService.inject     emailMassSendingService
	 * @scheduledThreadpoolExecutor.inject presideScheduledThreadpoolExecutor
	 * @hostname.inject                    coldbox:setting:heartbeats.emailqueue.hostname
	 */
	public function init(
		  required any     emailMassSendingService
		, required any     scheduledThreadpoolExecutor
		, required string  hostname
		,          numeric instanceNumber = 1
		,          string  threadName     = "Preside Email Queue Processor #arguments.instanceNumber#"
	){
		super.init(
			  threadName                  = arguments.threadName
			, scheduledThreadpoolExecutor = arguments.scheduledThreadpoolExecutor
			, intervalInMs                = 5000
			, feature                     = "emailQueueHeartBeat"
			, hostname                    = arguments.hostname
		);

		_setInstanceNumber( arguments.instanceNumber );
		_setEmailMassSendingService( arguments.emailMassSendingService );

		return this;
	}

	// PUBLIC API METHODS
	public void function $run() {
		try {
			if ( _getInstanceNumber() == 1 ) {
				_getEmailMassSendingService().autoQueueScheduledSendouts();
				_getEmailMassSendingService().requeueHungEmails();
			}
			_getEmailMassSendingService().processQueue();
		} catch( any e ) {
			$raiseError( e );
		}
	}

// GETTERS AND SETTERS
	private any function _getEmailMassSendingService() {
		return _taskmanagerService;
	}
	private void function _setEmailMassSendingService( required any emailMassSendingService ) {
		_taskmanagerService = arguments.emailMassSendingService;
	}

	private any function _getInstanceNumber() {
		return _instanceNumber;
	}
	private void function _setInstanceNumber( required any instanceNumber ) {
		_instanceNumber = arguments.instanceNumber;
	}
}