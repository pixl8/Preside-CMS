/**
 *
 * @singleton
 *
 */
component extends="cfconcurrent.ExecutorService" {

	/**
	 *  @maxConcurrent.inject    coldbox:setting:concurrency.pools.adhoc.maxConcurrent
	 *  @maxWorkQueueSize.inject coldbox:setting:concurrency.pools.adhoc.maxWorkQueueSize
	 */
	public function init(
		  required numeric maxConcurrent
		, required numeric maxWorkQueueSize
	){
		super.init(
			  argumentCollection = arguments
			, threadNamePattern  = "PresideAdhocPool-#_getAppId()#-Thread-${threadno}"
			, serviceName        = "PresideAdhocExecutorService"
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