/**
 * Represents a historical record of a task manager task run.
 * Includes any logging output, time taken and task status.
 *
 * @labelField name
 * @versioned  false
 *
 */
component extends="preside.system.base.SystemPresideObject"  {
	property name="task_key"   type="string"  dbtype="varchar" maxlength=100 required=true indexes="taskhistory|1,taskkey";
	property name="thread_id"  type="string"  dbtype="varchar" maxlength=100 required=true indexes="thread";
	property name="datecreated"                                                            indexes="taskhistory|2";
	property name="complete"   type="boolean" dbtype="boolean"               required=false default=false;
	property name="success"    type="boolean" dbtype="boolean"               required=false default=false;
	property name="log"        type="string"  dbtype="longtext"              required=false renderer="TaskLog";
	property name="time_taken" type="numeric" dbtype="int"                   required=false renderer="TaskTimeTaken";
}