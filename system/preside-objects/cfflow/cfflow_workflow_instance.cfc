/**
 * @feature                        cfflow
 * @nolabel                        true
 * @versioned                      false
 * @tablePrefix                    ""
 * @useCache                       false
 * @labelrenderer                  cfflow_instance_label
 * @datamanagerEnabled             true
 * @datamanagerAllowedOperations   read
 * @datamanagerDefaultSortOrder    datecreated
 */
component {
	property name="workflow_id"       type="string" dbtype="varchar" maxlength=100 required=true  uniqueindexes="instance|1" indexes="workflowid" autofilter=false;
	property name="owner"             type="string" dbtype="varchar" maxlength=100 required=false uniqueindexes="instance|2" indexes="owner" renderer="webflowOwner";
	property name="reference"         type="string" dbtype="varchar" maxlength=100 required=true  uniqueindexes="instance|3" indexes="reference,subreference|1";
	property name="sub_reference"     type="string" dbtype="varchar" maxlength=100 required=false uniqueindexes="instance|4" indexes="subreference|2" renderer="webflowInstanceReference";
	property name="sub_sub_reference" type="string" dbtype="varchar" maxlength=100 required=false uniqueindexes="instance|5" indexes="subreference|3";

	property name="completed" type="boolean" dbtype="boolean" default=false indexes="completed";

	property name="state" type="string" dbtype="longtext" autofilter=false;

	property name="instance_histories" relationship="one-to-many" relatedto="cfflow_workflow_instance_history" relationshipKey="instance" cloneable=false;
	property name="instance_steps"     relationship="one-to-many" relatedto="cfflow_workflow_instance_step"    relationshipKey="instance" cloneable=false;

	property name="current_step"   formula="MAX( ${prefix}instance_histories.result )" batcheditable=false autofilter=false control="none" renderer="webflowInstanceStepTitle";
	property name="current_status" formula="${prefix}id" renderer="webflowInstanceStatus";
}