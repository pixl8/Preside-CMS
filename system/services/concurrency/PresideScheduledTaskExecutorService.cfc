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
			, threadNamePattern  = "PresideTaskManagerPool-Thread-${threadno}"
			, serviceName        = "PresideScheduledTaskExecutorService"
		);

		return this;
	}

	public void function shutdown() {
		super.stop();
	}

}