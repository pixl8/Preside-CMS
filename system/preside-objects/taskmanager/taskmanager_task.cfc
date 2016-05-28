/**
 * Represents saved configuration and latest information on
 * task manager tasks.
 *
 * @labelField name
 * @versioned  false
 *
 */
component extends="preside.system.base.SystemPresideObject" displayname="Taskmanager task"  {
	property name="task_key"             type="string"  dbtype="varchar" maxlength=100 required=true uniqueindexes="taskkey";
	property name="enabled"              type="boolean" dbtype="boolean"               requried=false default=false;
	property name="last_ran"             type="date"    dbtype="datetime"              required=false;
	property name="next_run"             type="date"    dbtype="datetime"              required=false;
	property name="is_running"           type="boolean" dbtype="boolean"               required=false default=false;
	property name="running_thread"       type="string"  dbtype="varchar" maxlength=100 required=false;
	property name="run_expires"          type="date"    dbtype="datetime"              required=false;
	property name="was_last_run_success" type="boolean" dbtype="boolean"               required=false default=false;
	property name="last_run_time_taken"  type="numeric" dbtype="int"                   required=false;
	property name="priority"             type="numeric" dbtype="int"                   required=false default=0;
	property name="crontab_definition"   type="string"  dbtype="varchar" maxlength=100 required=false;
}