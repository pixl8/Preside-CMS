/**
 * @datamanagerEnabled                 true
 * @dataManagerExportEnabled           false
 * @datamanagerDisallowedOperations    add,clone,batchedit,viewversions
 * @datamanagerGridFields              label,object_name,schedule,created_by
 * @feature                            dataExport
 */
component extends="preside.system.base.SystemPresideObject" {
	property name="file_name"   required="true";
	property name="description"                                              maxlength=2000                                    autofilter=false;
	property name="object_name" required="true"               control="none" adminRenderer="objectName" renderer="objectName";
	property name="fields"      required="true"               control="none" maxlength=5000                                    autofilter=false;
	property name="exporter"    required="true" default="CSV" control="dataExporterPicker"                                     autofilter=false;
	property name="filter_string"                             control="none" type="string" dbtype="varchar" maxlength=1000     autofilter=false;
	property name="filter"                                    control="none" type="string" dbtype="text" feature="rulesEngine" autofilter=false;
	property name="saved_filter"                              control="none" type="string" dbtype="text" feature="rulesEngine" autofilter=false;
	property name="order_by"                                  control="none"                                                   autofilter=false;
	property name="search_query"                              control="none"                                                   autofilter=false;

	property name="created_by"   relationship="many-to-one"  relatedto="security_user" control="none" ondelete="set-null-if-no-cycle-check" onupdate="cascade-if-no-cycle-check";
	property name="recipients"   relationship="many-to-many" relatedto="security_user";
	property name="schedule"                                                          required="true" control="cronPicker" autofilter=false;

	property name="last_ran"             type="date"    dbtype="datetime"                            control="none";
	property name="next_run"             type="date"    dbtype="datetime"                            control="none";
	property name="is_running"           type="boolean" dbtype="boolean"               default=false control="none";
	property name="running_thread"       type="string"  dbtype="varchar" maxlength=255               control="none" autofilter=false;
	property name="running_machine"      type="string"  dbtype="varchar" maxlength=255               control="none" autofilter=false;
	property name="was_last_run_success" type="boolean" dbtype="boolean"               default=false control="none";
	property name="last_run_time_taken"  type="numeric" dbtype="int"                                 control="none";
}