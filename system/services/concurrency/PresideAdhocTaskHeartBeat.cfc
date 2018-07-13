/**
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	/**
	 * @adhoctaskmanagerService.inject adhocTaskManagerService
	 * @errorLogService.inject         errorLogService
	 *
	 */
	public any function init(
		  required any adhocTaskmanagerService
		, required any errorLogService
	) {
		_setAdhocTaskmanagerService( arguments.adhocTaskmanagerService );
		_setErrorLogService( arguments.errorLogService );

		return this;
	}

// PUBLIC API METHODS
	public void function run() {
		try {
			_getAdhocTaskmanagerService().runScheduledTasks();
		} catch( any e ) {
			_getErrorLogService().raiseError( e );
		}
	}

// GETTERS AND SETTERS
	private any function _getAdhocTaskmanagerService() {
		return _taskmanagerService;
	}
	private void function _setAdhocTaskmanagerService( required any adhocTaskmanagerService ) {
		_taskmanagerService = arguments.adhocTaskmanagerService;
	}

	private any function _getErrorLogService() {
		return _errorLogService;
	}
	private void function _setErrorLogService( required any errorLogService ) {
		_errorLogService = arguments.errorLogService;
	}
}