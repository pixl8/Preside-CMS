/**
 * @singleton      true
 * @presideService true
 *
 */
component extends="cfconcurrent.ScheduledThreadPoolExecutor" {

	public any function init() {
		var appName = _getAppName();

		return super.init(
			  serviceName       = "PresideScheduledThreadPool-#appName#"
			, maxConcurrent     = 0
			, threadNamePattern = "PresideScheduledThreadPool-#appName#-${poolno}-Thread-${threadno}"
		);
	}

// shutdown behaviour for when application is reloading
	public void function shutdown( ){
		super.stop();
	}

// monitoring
	public struct function getTaskStatuses() {
		var tasks     = getStoredTasks();
		var statuses  = StructNew( "linked" );
		var taskNames = StructKeyArray( tasks );

		ArraySort( taskNames, "textnocase" );

		for( var taskName in taskNames ) {
			var future = tasks[ taskName ].future;
			var task   = tasks[ taskName ].task;

			statuses[ taskName ] = {
				  isUp    = !future.isDone() && !future.isCancelled()
				, lastRun = task.getLastRun()
				, uptime  = task.getUptime()
			};
		}

		return statuses;
	}

// private helpers
	private string function _getAppName() {
		var appSettings = getApplicationMetadata();

		return appSettings.PRESIDE_APPLICATION_ID ?: ( appSettings.name ?: "" );
	}

}