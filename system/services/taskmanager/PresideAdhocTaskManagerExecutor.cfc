/**
 * @singleton      true
 * @presideService true
 *
 */
component extends="PresideTaskManagerExecutor" {
	/**
	 * @hostname.inject      coldbox:setting:heartbeats.adhocTask.hostname
	 * @maxConcurrent.inject coldbox:setting:heartbeats.adhocTask.poolSize
	 */
	public any function init(
		  required string  hostname
		,          numeric maxConcurrent = 0
	) {
		return super.init(
			  argumentCollection = arguments
			, serviceName        = "PresideAdhocTaskManagerThreadPool"
		);
	}

}