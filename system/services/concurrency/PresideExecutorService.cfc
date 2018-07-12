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
component extends="cfconcurrent.ExecutorService" {

	/**
	 * TODO: configuration options for maxCorrent/QueueSize
	 *
	 */
	public function init(
		  numeric maxConcurrent    = 0
		, numeric maxWorkQueueSize = 10000
		, string  threadPoolName   = "PresideThreadPool"
	){
		super.init( argumentCollection=arguments, serviceName="PresideExecutorService" );

		return this;
	}

	public void function shutdown() {
		super.stop();
	}

}