/**
 * @noLabel
 * @versioned  false
 * @feature    admin
 */
component extends="preside.system.base.SystemPresideObject" {
	property name="type"     type="string" dbtype="varchar" maxlength=50 uniqueIndexes="systemAlertScheduleType";
	property name="schedule" type="string" dbtype="varchar" maxlength=30;
	property name="last_run" type="date"   dbtype="datetime";
	property name="next_run" type="date"   dbtype="datetime";
}