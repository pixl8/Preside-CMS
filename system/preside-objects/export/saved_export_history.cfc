/**
 * @datamanagerEnabled                 true
 * @nolabel                            true
 * @versioned                          false
 * @dataManagerExportEnabled           false
 * @datamanagerDisallowedOperations    read,add,edit,clone
 * @datamanagerGridFields              datecreated,exporter,complete,success,time_taken
 * @datamanagerDefaultSortOrder        datecreated desc
 * @feature                            dataExport
 */
component extends="preside.system.base.SystemPresideObject" {
	property name="saved_export" relationship="many-to-one" relatedto="saved_export" required="true" indexes="exporthistory|1,exportid" autofilter=false batchEditable=false;
	property name="exporter"     default="CSV"                                                                                          autofilter=false batchEditable=false;

	property name="thread_id"                                  maxlength=100 required=true indexes="thread"                                            autofilter=false batchEditable=false;
	property name="machine_id"                                 maxlength=100 required=true indexes="machine"                                           autofilter=false batchEditable=false;
	property name="datecreated"                                                            indexes="exporthistory|2"                                                    batchEditable=false;
	property name="complete"   type="boolean" dbtype="boolean"                             default=false                                                                batchEditable=false;
	property name="success"    type="boolean" dbtype="boolean"                             default=false                                                                batchEditable=false;
	property name="log"        type="string"  dbtype="longtext"                            renderer="TaskLog"                                          autofilter=false batchEditable=false;
	property name="time_taken" type="numeric" dbtype="int"                                 renderer="TaskTimeTaken"                                    autofilter=false batchEditable=false;
	property name="filepath"                                   maxlength=1000                                                                          autofilter=false batchEditable=false;
}