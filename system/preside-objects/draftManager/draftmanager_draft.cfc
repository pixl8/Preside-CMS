/**
 * @versioned                       false
 * @dataManagerEnabled              true
 * @datamanagerGridFields           label,_status,datecreated,datemodified
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

	property name="steps" formula="${prefix}id" renderer="DraftSteps";

}