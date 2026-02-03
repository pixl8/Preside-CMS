/**
 * Represents a line in a task manager task log
 *
 * @versioned      false
 * @useCache       false
 * @noLabel        true
 * @nodatemodified true
 * @nodatecreated  true
 * @feature        taskManager
 */
component extends="preside.system.base.SystemPresideObject"  {
	property name="id" required=true type="numeric" dbtype="bigint" generator="increment";

	property name="history" relationship="many-to-one" relatedto="taskmanager_task_history" required=true ondelete="cascade";

	property name="ts"       required=true type="numeric" dbtype="bigint";
	property name="severity" required=true type="numeric" dbtype="tinyint";
	property name="line"     required=true type="string"  dbtype="longtext";
}
