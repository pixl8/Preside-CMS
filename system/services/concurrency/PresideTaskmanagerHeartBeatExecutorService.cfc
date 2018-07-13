/**
 *
 * @singleton
 *
 */
component extends="cfconcurrent.ScheduledThreadPoolExecutor" {

	/**
	 * @presideTaskManagerHeartBeat.inject presideTaskManagerHeartBeat
	 *
	 */
	public function init( required any presideTaskManagerHeartBeat ){
		super.init(
			  serviceName       = "PresideTaskManagerHeartbeatExecutorService"
			, maxConcurrent     = 1
			, threadPoolName    = "PresideTaskManagerHeartbeatThreadPool"
			, threadNamePattern = "PresideTaskManagerHeartBeat-#_getAppId()#"
		);

		_setHeartbeatTask( arguments.presideTaskManagerHeartBeat );

		return this;
	}

	public void function start() {
		super.start();
		super.scheduleAtFixedRate(
			  id           = "PresideHeartBeat"
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