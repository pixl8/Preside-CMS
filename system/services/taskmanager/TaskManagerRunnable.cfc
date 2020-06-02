component {

	public any function init(
		  required any    service
		, required string taskKey
		, required struct args
		, required string threadId
		, required any    logger
	) {
		variables.service  = arguments.service;
		variables.taskKey  = arguments.taskKey;
		variables.args     = arguments.args;
		variables.threadId = arguments.threadId;
		variables.logger   = arguments.logger;
	}


	public void function run() {
		service.runTaskWithinThread(
			  taskKey  = taskKey
			, args     = args
			, threadId = threadId
			, logger   = logger
		);
	}


}