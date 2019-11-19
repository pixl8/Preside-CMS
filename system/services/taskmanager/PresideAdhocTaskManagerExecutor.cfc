/**
 * @singleton      true
 * @presideService true
 *
 */
component extends="PresideTaskManagerExecutor" {
	/**
	 * @hostname.inject coldbox:setting:heartbeats.adhocTask.hostname
	 *
	 */
	public any function init( required string hostname ) {
		return super.init( argumentCollection=arguments, serviceName="PresideAdhocTaskManagerThreadPool" )
	}

}