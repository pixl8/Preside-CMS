/**
 * Service responsible for the business logic of running ad-hoc tasks
 *
 * @singleton
 * @presideService
 * @autodoc
 *
 */
component displayName="Ad-hoc Task Manager Service" {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	/**
	 * Registers a new task, optionally running it there and then
	 * in a background thread
	 *
	 * @autodoc    true
	 * @event      Coldbox event that will be run
	 * @args       Args struct to pass to the coldbox event
	 * @adminOwner Optional admin user ID, owner of the task
	 */
	public string function createTask(
		  required string event
		,          struct args       = {}
		,          string adminOwner = ""
	) {
		var taskId = $getPresideObject( "taskmanager_adhoc_task" ).insertData( {
			  event       = arguments.event
			, event_args  = SerializeJson( arguments.args )
			, admin_owner = arguments.adminOwner
		} );

		return taskId;
	}

	/**
	 * Runs a registered task
	 *
	 * @autodoc true
	 * @taskId  ID of the task to run
	 */
	public boolean function runTask( required string taskId ) {
		var task  = getTask( arguments.taskId );
		var event = task.event ?: "";
		var args  = IsJson( task.event_args ?: "" ) ? DeserializeJson( task.event_args ) : {};
		var e     = "";

		try {
			$getColdbox().runEvent(
				  event          = task.event
				, eventArguments = { args=args, logger=_getTaskLogger( taskId ), progress=_getTaskProgressReporter( taskId ) }
				, private        = true
				, prepostExempt  = true
			);
		} catch( any e ) {
			$raiseError( error=e );
			return false;
		}

		return true;
	}

	/**
	 * Gets the database record for the given task ID
	 *
	 * @autodoc true
	 * @taskId  ID of the task to get
	 */
	public query function getTask( required string taskId ) {
		return $getPresideObject( "taskmanager_adhoc_task" ).selectData( id=arguments.taskId );
	}

// PRIVATE HELPERS
	private any function _getTaskLogger() {
		return "stub";
	}

	private any function _getTaskProgressReporter() {
		return "stub";
	}

}