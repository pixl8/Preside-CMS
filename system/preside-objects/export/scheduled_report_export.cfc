/**
 * @datamanagerEnabled                 true
 * @versioned                          false
 * @dataManagerExportEnabled           false
 * @datamanagerDisallowedOperations    add,clone
 * @datamanagerGridFields              label,saved_report,schedule,was_last_run_success,last_ran,next_run
 */
component extends="preside.system.base.SystemPresideObject" {
	property name="saved_report" relationship="many-to-one"  relatedto="saved_report"  required="true";
	property name="recipients"   relationship="many-to-many" relatedto="security_user" required="true";
	property name="schedule"                                                           required="true" control="cronPicker" autofilter=false;

	property name="last_ran"             type="date"    dbtype="datetime"                            control="none";
	property name="next_run"             type="date"    dbtype="datetime"                            control="none";
	property name="is_running"           type="boolean" dbtype="boolean"               default=false control="none";
	property name="running_thread"       type="string"  dbtype="varchar" maxlength=255               control="none";
	property name="running_machine"      type="string"  dbtype="varchar" maxlength=255               control="none";
	property name="was_last_run_success" type="boolean" dbtype="boolean"               default=false control="none";
	property name="last_run_time_taken"  type="numeric" dbtype="int"                                 control="none";
}