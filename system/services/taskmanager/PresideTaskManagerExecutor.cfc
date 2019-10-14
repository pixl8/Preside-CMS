/**
 * @singleton      true
 * @presideService true
 *
 */
component extends="cfconcurrent.ExecutorService" {

	public any function init() {
		var appName = _getAppName();

		return super.init(
			  serviceName       = "PresideTaskManagerThreadPool-#appName#"
			, maxConcurrent     = 0
			, threadNamePattern = "PresideTaskManagerThreadPool-#appName#-${poolno}-Thread-${threadno}"
		);
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

}