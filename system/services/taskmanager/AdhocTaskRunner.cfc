/**
 * A runnable object to be used
 * with cfconcurrent executors for running
 * background tasks in thread pools
 *
 *
 * @singleton false
 *
 */
component {

	public any function init(
		  required any    adhocTaskManagerService
		, required any    errorLogService
		, required string taskId
	) {
		variables.adhocTaskManagerService = arguments.adhocTaskManagerService;
		variables.errorLogService         = arguments.errorLogService;
		variables.taskId                  = arguments.taskId;
	}

	public void function run() {
		try {
			adhocTaskManagerService.runTask( taskId );
		} catch( any e ) {
			errorLogService.raiseError( e );
		}
	}

}