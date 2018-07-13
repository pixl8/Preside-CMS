/**
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	/**
	 * @taskmanagerService.inject taskManagerService
	 * @errorLogService.inject    errorLogService
	 *
	 */
	public any function init(
		  required any taskmanagerService
		, required any errorLogService
	) {
		_setTaskmanagerService( arguments.taskmanagerService );
		_setErrorLogService( arguments.errorLogService );

		return this;
	}

// PUBLIC API METHODS
	public void function run() {
		try {
			var taskManagerService = _getTaskmanagerService();

			taskmanagerService.cleanupNoLongerRunningTasks();
			var result = taskmanagerService.runScheduledTasks();

			if ( Len( Trim( result.error ?: "" ) ) ) {
				throw( type="preside.taskmanager.configuration", message=result.error );
			}
		} catch( any e ) {
			_getErrorLogService().raiseError( e );
		}
	}

// GETTERS AND SETTERS
	private any function _getTaskmanagerService() {
		return _taskmanagerService;
	}
	private void function _setTaskmanagerService( required any taskmanagerService ) {
		_taskmanagerService = arguments.taskmanagerService;
	}

	private any function _getErrorLogService() {
		return _errorLogService;
	}
	private void function _setErrorLogService( required any errorLogService ) {
		_errorLogService = arguments.errorLogService;
	}
}