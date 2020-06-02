/**
 * @singleton      true
 * @presideService true
 *
 */
component extends="cfconcurrent.ExecutorService" {

	/**
	 * @hostname.inject coldbox:setting:heartbeats.taskmanager.hostname
	 *
	 */
	public any function init( required string hostname, string serviceName="PresideTaskManagerThreadPool" ) {
		var appName = _getAppName();

		_setHostname( arguments.hostName );

		return super.init(
			  serviceName       = "#arguments.serviceName#-#appName#"
			, maxConcurrent     = 0
			, threadNamePattern = "#arguments.serviceName#-#appName#-${poolno}-Thread-${threadno}"
		);
	}

// submit, passing hostname set in config
	public function submit( task, hostname=_getHostName() ) {
		return super.submit( argumentCollection=arguments );
	}

// shutdown behaviour for when application is reloading
	public void function shutdown( ){
		super.stop();
	}

// private helpers
	private string function _getAppName() {
		var appSettings = getApplicationMetadata();

		return appSettings.PRESIDE_APPLICATION_ID ?: ( appSettings.name ?: "" );
	}

// getters and setters
	private string function _getHostname() {
	    return _hostname;
	}
	private void function _setHostname( required string hostname ) {
	    _hostname = arguments.hostname;
	}

}