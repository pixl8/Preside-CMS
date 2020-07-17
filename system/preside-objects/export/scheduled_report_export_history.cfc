/**
 * @datamanagerEnabled                 true
 * @nolabel                            true
 * @versioned                          false
 * @dataManagerExportEnabled           false
 * @datamanagerDisallowedOperations    read,add,edit,clone
 * @datamanagerGridFields              datecreated,complete,success,time_taken
 * @datamanagerDefaultSortOrder        datecreated desc
 */
component extends="preside.system.base.SystemPresideObject" {
	property name="scheduled_report" relationship="many-to-one" relatedto="scheduled_report_export" required="true" indexes="exporthistory|1,reportid" autofilter=false feature="savereport";

	property name="thread_id"                                  maxlength=100 required=true indexes="thread"                                            autofilter=false;
	property name="machine_id"                                 maxlength=100 required=true indexes="machine"                                           autofilter=false;
	property name="datecreated"                                                            indexes="exporthistory|2";
	property name="complete"   type="boolean" dbtype="boolean"                             default=false;
	property name="success"    type="boolean" dbtype="boolean"                             default=false;
	property name="log"        type="string"  dbtype="longtext"                            renderer="TaskLog"                                          autofilter=false;
	property name="time_taken" type="numeric" dbtype="int"                                 renderer="TaskTimeTaken"                                    autofilter=false;
	property name="filepath"                                   maxlength=1000                                                                          autofilter=false;
}