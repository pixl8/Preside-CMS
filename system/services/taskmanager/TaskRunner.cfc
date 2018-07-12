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
		, required string taskId
	) {
		variables.adhocTaskManagerService = arguments.adhocTaskManagerService;
		variables.taskId                  = arguments.taskId;
	}

	public void function run() {
		adhocTaskManagerService.runTask( taskId );
	}

}