/**
 * @versioned                       false
 * @dataManagerEnabled              true
 * @datamanagerGridFields           label,_status,datecreated,datemodified
 * @datamanagerHiddenGridFields     _object_name,_record_id
 * @datamanagerDisallowedOperations clone
 * @datamanagerWorkflowEnabled      true
 * @datamanagerWorkflowDefaultFlow  draftDefault
 */
component {

	property name="_object_name" type="string" dbtype="varchar"  batchEditable=false excludeDataExport=true autoFilter=false adminRenderer="none";
	property name="_record_id"   type="string" dbtype="varchar"  batchEditable=false excludeDataExport=true autoFilter=false adminRenderer="none";
	property name="_workflow_id" type="string" dbtype="varchar"  batchEditable=false excludeDataExport=true autoFilter=false adminRenderer="none";
	property name="_data"        type="string" dbtype="longtext" batchEditable=false excludeDataExport=true autoFilter=false adminRenderer="none";
	property name="_status"      type="string" dbtype="varchar"  batchEditable=false excludeDataExport=true autoFilter=false adminRenderer="none" enum="draftStatus";

	property name="_security_user_created"  relationship="many-to-one" relatedTo="security_user" onDelete="set-null-if-no-cycle-check" batchEditable=false excludeDataExport=true autoFilter=false;
	property name="_security_user_modified" relationship="many-to-one" relatedTo="security_user" onDelete="set-null-if-no-cycle-check" batchEditable=false excludeDataExport=true autoFilter=false;

}