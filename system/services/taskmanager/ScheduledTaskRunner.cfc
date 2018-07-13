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
		  required any    taskManagerService
		, required any    errorLogService
		, required string threadId
		, required string taskKey
		, required struct args
		, required any    logger
	) {
		variables.taskManagerService = arguments.taskManagerService;
		variables.errorLogService    = arguments.errorLogService;
		variables.threadId           = arguments.threadId;
		variables.taskKey            = arguments.taskKey;
		variables.args               = arguments.args;
		variables.logger             = arguments.logger;
		variables.canInfo            = arguments.logger.canInfo();

		if ( canInfo ) {
			logger.info( "Task queued ready to start..." );
		}
	}

	public void function run() {
		try {
			if ( canInfo ) {
				logger.info( "Task starting now..." );
			}

			taskManagerService.runTaskWithinThread( taskKey, args, threadId, logger );
		} catch( any e ) {
			errorLogService.raiseError( e );
		}
	}

}