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
		  required string  event
		,          struct  args       = {}
		,          string  adminOwner = ""
		,          boolean runNow     = false
	) {
		var taskId = $getPresideObject( "taskmanager_adhoc_task" ).insertData( {
			  event       = arguments.event
			, event_args  = SerializeJson( arguments.args )
			, admin_owner = arguments.adminOwner
		} );

		if ( arguments.runNow ) {
			runTaskInThread( taskId=taskId );
		}

		return taskId;
	}

	/**
	 * Runs a registered task
	 *
	 * @autodoc true
	 * @taskId  ID of the task to run
	 */
	public boolean function runTask( required string taskId ) {
		lock timeout="1" name="adhocRunTask#arguments.taskId#" {
			var task  = getTask( arguments.taskId );
			var event = task.event ?: "";
			var args  = IsJson( task.event_args ?: "" ) ? DeserializeJson( task.event_args ) : {};
			var e     = "";

			if ( task.status == "running" ) {
				$raiseError( error={
					  type    = "AdHoTaskManagerService.task.already.running"
					, message = "Task not run. The task with ID, [#arguments.taskId#], is already running."
				} );

				return false;
			}

			try {
				$getColdbox().runEvent(
					  event          = task.event
					, eventArguments = { args=args, logger=_getTaskLogger( taskId ), progress=_getTaskProgressReporter( taskId ) }
					, private        = true
					, prepostExempt  = true
				);
			} catch( any e ) {
				failTask( taskId=arguments.taskId );
				$raiseError( error=e );
				return false;
			}

			completeTask( taskId=arguments.taskId );
		}

		return true;
	}

	/**
	 * Runs the task in a background thread
	 *
	 * @autodoc true
	 * @taskId  ID of the task to run
	 */
	public void function runTaskInThread( required string taskId ) {
		if ( _inThread() ) {
			runTask( arguments.taskId );
		}

		thread action="run" name="runTask-#CreateUUId()#" taskId=arguments.taskId {
			runTask( taskId=attributes.taskId );
		}
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

	/**
	 * Marks a task as complete
	 *
	 * @autodoc true
	 * @taskId ID of the task to mark as complete
	 */
	public void function completeTask( required string taskId ) {
		$getPresideObject( "taskmanager_adhoc_task" ).updateData(
			  id   = arguments.taskId
			, data = { status="succeeded" }
		);
	}

	/**
	 * Marks a task as failed
	 *
	 * @autodoc true
	 * @taskId  ID of the task to mark as failed
	 */
	public void function failTask( required string taskId ) {
		$getPresideObject( "taskmanager_adhoc_task" ).updateData(
			  id   = arguments.taskId
			, data = { status="failed" }
		);
	}

	/**
	 * Sets progress on a task
	 *
	 * @autodoc  true
	 * @taskId   ID of the task
	 * @progress Progress percentage of the task
	 */
	public void function setProgress( required string taskId, required numeric progress ) {
		$getPresideObject( "taskmanager_adhoc_task" ).updateData(
			  id   = arguments.taskId
			, data = { progress_percentage=arguments.progress }
		);
	}

	/**
	 * Sets the result of a task
	 *
	 * @autodoc  true
	 * @taskId   ID of the task
	 * @result   The task result (will be serialized when saving against DB record)
	 */
	public void function setResult( required string taskId, required any result ) {
		$getPresideObject( "taskmanager_adhoc_task" ).updateData(
			  id   = arguments.taskId
			, data = { result=SerializeJson( arguments.result ) }
		);
	}


// PRIVATE HELPERS
	private any function _getTaskLogger() {
		return "stub";
	}

	private any function _getTaskProgressReporter() {
		return "stub";
	}

	private boolean function _inThread() {
		var engine = "ADOBE";

		if ( server.coldfusion.productname == "Railo" ){ engine = "RAILO"; }
		if ( server.coldfusion.productname == "Lucee" ){ engine = "LUCEE"; }

		switch( engine ){
			case "ADOBE"	: {
				if( findNoCase( "cfthread", createObject( "java", "java.lang.Thread" ).currentThread().getThreadGroup().getName() ) ){
					return true;
				}
				break;
			}
			case "RAILO" : case "LUCEE" : {
				return getPageContext().hasFamily();
				break;
			}
		} //end switch statement.

		return false;
	}

}