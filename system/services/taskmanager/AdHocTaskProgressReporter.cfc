/**
 * Service to report progress on a task. An instance of this object
 * will be passed to any ad-hoc task handlers and can then be used
 * to report progress of the running of the task
 *
 * @autodoc
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

	/**
	 * Sets the progress percentage of your task. See also [[taskmanager-adhoctasks]].
	 *
	 * @autodoc true
	 * @progress The % complete of your task
	 */
	public void function setProgress( required numeric progress ) {
		_getAdhocTaskManagerService().setProgress(
			  progress = arguments.progress
			, taskId   = _getTaskId()
		);
	}

	/**
	 * Sets the result for your task. Can then be used
	 * for later task result viewing / processing.
	 * See also [[taskmanager-adhoctasks]].
	 *
	 * @autodoc true
	 * @result  A serializable result, i.e. a struct, array, simple value, etc. Anything you like.
	 */
	public void function setResult( required any result ) {
		_getAdhocTaskManagerService().setResult(
			  result = arguments.result
			, taskId = _getTaskId()
		);
	}

	/**
	 * Sets the result URL for your task. If using
	 * the built-in admin monitoring UI, users will
	 * be directed to this URL on successful task completion.
	 * See also [[taskmanager-adhoctasks]].
	 *
	 * @autodoc   true
	 * @resultUrl URL to which user will be redirected to on successful completion of task
	 */
	public void function setResultUrl( required string resultUrl ) {
		_getAdhocTaskManagerService().setResult(
			  resultUrl = arguments.resultUrl
			, taskId    = _getTaskId()
		);
	}

	/**
	 * Returns true if the task has been cancelled or
	 * is no longer valid. Call this from your task logic
	 * to exit early from the task and cleanup gracefully
	 * if required.
	 *
	 * See also [[taskmanager-adhoctasks]].
	 *
	 * @autodoc true
	 */
	public boolean function isCancelled() {
		var task = _getAdhocTaskManagerService().getTask( _getTaskId() );

		return !task.recordCount || task.status != "running";
	}

	/**
	 * Marks a task as failed
	 *
	 * @autodoc    true
	 * @error      Error that prompted task failure
	 * @forceRetry If true, will ignore retry config and automatically queue for retry
	 */
	public void function failTask( struct error={}, boolean forceRetry=false ) {
		_getAdhocTaskManagerService().failTask(
			  taskId 			= _getTaskId()
			, error    		= arguments.error
			, forceRetry 	= arguments.forceRetry
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