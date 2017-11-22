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

	public void function setProgress( required numeric progress ) {
		_getAdhocTaskManagerService().setProgress(
			  progress = arguments.progress
			, taskId   = _getTaskId()
		);
	}

	public void function setResult( required any result ) {
		_getAdhocTaskManagerService().setResult(
			  result = arguments.result
			, taskId = _getTaskId()
		);
	}

	public void function setResultUrl( required string resultUrl ) {
		_getAdhocTaskManagerService().setResult(
			  resultUrl = arguments.resultUrl
			, taskId    = _getTaskId()
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