/**
 * Abstraction wrapper for taskmanager configuration.
 *
 * @singleton
 * @autodoc
 */
component displayName="TaskManager Configuration Wrapper" {

// CONSTRUCTOR
	/**
	 * @handlerDirectories.inject presidecms:directories:handlers
	 */
	public any function init( required array handlerDirectories ) {
		_setHandlerDirectories( arguments.handlerDirectories );

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Returns a struct of configured task (where struct keys
	 * are the id of the task and values are a struct
	 * containing task information).
	 *
	 * @autodoc
	 */
	public struct function getConfiguredTasks() {
		var tasks = {};

		for( var dir in _getHandlerDirectories() ){
			for( var file in [ "ScheduledTasks.cfc", "Tasks.cfc" ] ) {
				var filePath = dir & "/" & file;
				var handler  = LCase( ReReplace( file, "\.cfc$", "" ) );

				if ( FileExists( filePath ) ) {
					var componentPath = Replace( filePath, "/", ".", "all" );
					    componentPath = ReReplace( componentPath, "\.cfc$", "" );

					var meta = getComponentMetaData( componentPath );

					for( var f in meta.functions ){
						var isScheduledTaskMethod = Len( Trim( f.schedule ?: "" ) );
						if ( isScheduledTaskMethod ) {
							tasks[ f.name ] = {
								  event        = "#handler#.#f.name#"
								, schedule     = _parseCronTabSchedule( f.schedule )
								, name         = f.displayName ?: f.name
								, description  = f.hint        ?: ""
								, timeout      = Val( f.timeout ?: 600 )
								, priority     = Val( f.priority ?: 0 )
								, isScheduled  = f.schedule != "disabled"
								, displayGroup = f.displayGroup ?: "default"
							};
						}
					}

				}
			}
		}

		return tasks;
	}

// PRIVATE HELPERS
	private string function _parseCronTabSchedule( required string cronTabExpression ) {
		return Replace( arguments.cronTabExpression, "*\/", "*/", "all" ); // for javadoc style attribute expressison, where */ would end the javadoc comment, we allow *\/ as a syntax and clean it up here
	}

// GETTERS AND SETTERS
	private any function _getHandlerDirectories() {
		return _handlerDirectories;
	}
	private void function _setHandlerDirectories( required any handlerDirectories ) {
		_handlerDirectories = arguments.handlerDirectories;
	}

}