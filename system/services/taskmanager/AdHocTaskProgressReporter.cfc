/**
 * Service to report progress on a task. An instance of this object
 * will be passed to any ad-hoc task handlers and can then be used
 * to report progress of the running of the task
 *
 */
component {

// CONSTRUCTOR
	public any function init(
		  required any    adhocTaskManagerService
		, required string taskId
	) {
		_setAdhocTaskManagerService( arguments.adhocTaskManagerService );
		_setTaskId( arguments.taskId );

		return this;
	}

	public void function setProgress() {
		_getAdhocTaskManagerService().setProgress(
			  argumentCollection = arguments
			, taskId             = _getTaskId()
		);
	}

	public void function setResult() {
		_getAdhocTaskManagerService().setResult(
			  argumentCollection = arguments
			, taskId             = _getTaskId()
		);
	}


// GETTERS AND SETTERS
	private any function _getAdhocTaskManagerService() {
		return _adhocTaskManagerService;
	}
	private void function _setAdhocTaskManagerService( required any adhocTaskManagerService ) {
		_adhocTaskManagerService = arguments.adhocTaskManagerService;
	}

	private string function _getTaskId() {
		return _taskId;
	}
	private void function _setTaskId( required string taskId ) {
		_taskId = arguments.taskId;
	}
}