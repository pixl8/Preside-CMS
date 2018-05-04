/**
 * Service that provides task scheduling. This implementation
 * is a simple wrapper to the cfschedule tag and can be
 * swapped out with any other implementation
 *
 * @singleton
 * @presideService
 * @autodoc
 *
 */
component displayName="Task scheduler" {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	public void function createTask(
		  required string  task
		, required string  url
		,          numeric port          = 80
		,          string  username      = ""
		,          string  password      = ""
		,          string  proxyServer   = ""
		,          string  proxyPort     = ""
		,          string  proxyUser     = ""
		,          string  proxyPassword = ""
		,          date    startdate     = "1900-01-01"
		,          time    startTime     = "00:00:00"
		,          string  interval      = ""
		,          boolean hidden        = false
		,          boolean autoDelete    = true
	) {
		schedule action="update" attributeCollection=arguments;
	}

	public void function deleteTask( required string task ) {
		schedule action="delete" task="#arguments.task#";
	}

	public void function deleteTasks( required string taskPattern, array preserveTasks=[] ) {
		var tasks       = "";

		schedule action="list" returnvariable="tasks";

		for( var task in tasks ) {
			if ( !arguments.preserveTasks.findNoCase( task.task ) && task.task.reFindNoCase( arguments.taskPattern ) ) {
				schedule action="delete" task=task.task;
			}
		}
	}

}