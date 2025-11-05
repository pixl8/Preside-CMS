/**
 * @versioned                       false
 * @dataManagerEnabled              true
 * @datamanagerGridFields           label,_status,datecreated,datemodified
 * @datamanagerDisallowedOperations clone
 * @datamanagerWorkflowEnabled      true
 * @datamanagerWorkflowDefaultFlow  draftDefault
 */
component {

	property name="object_name" type="string" dbtype="varchar"  searchEnabled=true searchSearchable=false batchEditable=false autoFilter=false;
	property name="record_id"   type="string" dbtype="varchar"  searchEnabled=true searchSearchable=false batchEditable=false autoFilter=false;
	property name="workflow_id" type="string" dbtype="varchar"  searchEnabled=true searchSearchable=false batchEditable=false autoFilter=false;
	property name="data"        type="string" dbtype="longtext" searchEnabled=true searchSearchable=false batchEditable=false autoFilter=false;
	property name="_status"     type="string" dbtype="varchar"  searchEnabled=true searchSearchable=false batchEditable=false autoFilter=false enum="draftStatus";

	property name="steps" formula="${prefix}id" renderer="DraftSteps";

}