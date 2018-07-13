/**
 *
 * @singleton
 *
 */
component extends="cfconcurrent.ExecutorService" {

	/**
	 *  @maxConcurrent.inject    coldbox:setting:concurrency.pools.scheduledTasks.maxConcurrent
	 *  @maxWorkQueueSize.inject coldbox:setting:concurrency.pools.scheduledTasks.maxWorkQueueSize
	 */
	public function init(
		  required numeric maxConcurrent
		, required numeric maxWorkQueueSize
	){
		super.init(
			  argumentCollection = arguments
			, threadNamePattern  = "PresideTaskManagerPool-#_getAppId()#-Thread-${threadno}"
			, serviceName        = "PresideScheduledTaskExecutorService"
		);

		return this;
	}

	public void function shutdown() {
		super.stop();
	}

// GETTERS AND SETTERS
	private string function _getAppId() {
		var appSettings = getApplicationSettings();

		return appSettings.PRESIDE_APPLICATION_ID ?: ( appSettings.name ?: CreateUUId() );
	}
}