component {

	public any function init(
		  required any    service
		, required string taskId
	) {
		variables.service = arguments.service;
		variables.taskId  = arguments.taskId;
	}


	public void function run() {
		service.runTask( taskId=taskId );
	}


}