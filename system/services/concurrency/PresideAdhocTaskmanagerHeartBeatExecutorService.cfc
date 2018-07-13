/**
 *
 * @singleton
 *
 */
component extends="cfconcurrent.ScheduledThreadPoolExecutor" {

	/**
	 * @presideAdhocTaskHeartBeat.inject presideAdhocTaskHeartBeat
	 *
	 */
	public function init( required any presideAdhocTaskHeartBeat ){
		super.init(
			  serviceName       = "PresideAdhocTaskHeartbeatExecutorService"
			, maxConcurrent     = 1
			, threadPoolName    = "PresideAdhocTaskHeartbeatThreadPool"
			, threadNamePattern = "PresideAdhocTaskHeartBeat-#_getAppId()#"
		);

		_setHeartbeatTask( arguments.presideAdhocTaskHeartBeat );

		return this;
	}

	public void function start() {
		super.start();
		super.scheduleAtFixedRate(
			  id           = "PresideAdhocHeartBeat"
			, task         = _getHeartbeatTask()
			, initialDelay = 0
			, period       = 1
			, timeUnit     = getObjectFactory().SECONDS
		);
	}

	public void function shutdown() {
		super.stop();
	}

// GETTERS / SETTERS
	private any function _getHeartbeatTask() {
		return _presideHeartBeat;
	}
	private void function _setHeartbeatTask( required any presideHeartBeat ) {
		_presideHeartBeat = arguments.presideHeartBeat;
	}

	private string function _getAppId() {
		var appSettings = getApplicationSettings();

		return appSettings.PRESIDE_APPLICATION_ID ?: ( appSettings.name ?: CreateUUId() );
	}
}