/**
 * This is a transient service that gets passed to any scheduled task hander
 * so that the task can maintain a task run log in a space that is unique
 * to the running task.
 *
 * @autodoc
 *
 */
component displayName="TaskManager Logger Wrapper" {

// CONSTRUCTOR
	public any function init( required any logboxLogger, required string taskRunId, required any taskHistoryDao ) {
		_setLogboxLogger( arguments.logboxLogger );
		_setTaskRunId( arguments.taskRunId );
		_setTaskHistoryDao( arguments.taskHistoryDao );

		return this;
	}

// PUBLIC API METHODS
	public any function onMissingMethod( required string methodName, struct methodArgs={} ) {
		var loggingMethods = [ "DEBUG" ,"INFO" ,"WARN" ,"ERROR" ,"FATAL" ,"OFF" ];
		var logger         = _getLogboxLogger();

		if ( loggingMethods.findNoCase( arguments.methodName ) ) {
			var args = {
				  message   = arguments.methodArgs[1] ?: ( arguments.methodArgs.message   ?: "" )
				, extraInfo = arguments.methodArgs[2] ?: ( arguments.methodArgs.extraInfo ?: {} )
			};
			args.extraInfo.taskRunId      = _getTaskRunId();
			args.extraInfo.taskHistoryDao = _getTaskHistoryDao();

			sleep(1); // cheeky way to have threads get interrupted if they don't have their own safe interruption logic

			return logger[ arguments.methodName ]( argumentCollection=args );
		}

		return logger[ arguments.methodName ]( argumentCollection=arguments.methodArgs );
	}


// GETTERS AND SETTERS
	private any function _getLogboxLogger() {
		return _logboxLogger;
	}
	private void function _setLogboxLogger( required any logboxLogger ) {
		_logboxLogger = arguments.logboxLogger;
	}

	private any function _getTaskRunId() {
		return _taskRunId;
	}
	private void function _setTaskRunId( required any taskRunId ) {
		_taskRunId = arguments.taskRunId;
	}

	private any function _getTaskHistoryDao() {
		return _taskHistoryDao;
	}
	private void function _setTaskHistoryDao( required any taskHistoryDao ) {
		_taskHistoryDao = arguments.taskHistoryDao;
	}
}
