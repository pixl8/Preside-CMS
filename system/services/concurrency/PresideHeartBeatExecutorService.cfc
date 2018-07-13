/**
 * A special cfconcurrent.ExecutorService that adds
 * a 'shutdown()' proxy to the 'stop()' method to automatically
 * shutdown onApplicationEnd().
 *
 * It also passes in constructor arguments from configuration.
 *
 * @singleton
 *
 */
component extends="cfconcurrent.ScheduledThreadPoolExecutor" {

	/**
	 * @presideHeartbeat.inject presideHeartbeat
	 *
	 */
	public function init( required any presideHeartbeat ){
		super.init(
			  serviceName       = "PresideHeartbeatExecutorService"
			, maxConcurrent     = 1
			, threadPoolName    = "PresideHeartbeatThreadPool"
			, threadNamePattern = "PresideHeartBeat"
		);

		_setPresideHeartBeat( arguments.presideHeartbeat );

		return this;
	}

	public void function start() {
		super.start();
		super.scheduleAtFixedRate(
			  id           = "PresideHeartBeat"
			, task         = _getPresideHeartbeat()
			, initialDelay = 0
			, period       = 1
			, timeUnit     = getObjectFactory().SECONDS
		);
	}

	public void function shutdown() {
		super.stop();
	}

// GETTERS / SETTERS
	private any function _getPresideHeartBeat() {
		return _presideHeartBeat;
	}
	private void function _setPresideHeartBeat( required any presideHeartBeat ) {
		_presideHeartBeat = arguments.presideHeartBeat;
	}

}