/**
 * @feature                         webflow
 * @tablePrefix                     ""
 * @tenant                          site
 * @datamanagerEnabled              true
 * @datamanagerGridFields           label,step_count,timeout_in_minutes,active_instances_count,timedout_instances_count,archived_instances_count,completed_archived_count,instance_completion_rate,datemodified
 * @datamanagerDisallowedOperations add,delete,clone
 */
component {
	property name="webflow_id"         type="string"  dbtype="varchar" maxlength=100 required=true  indexes="webflowid"  uniqueindexes="webflowref|1";
	property name="instance_ref"       type="string"  dbtype="varchar" maxlength=100 required=false indexes="webflowref" uniqueindexes="webflowref|2";
	property name="weflow_config_hash" type="string"  dbtype="varchar" maxlength=35  required=false indexes="confighash";
	property name="progressbar_layout" type="string"  dbtype="varchar" maxlength=20  required=false indexes="prgoressbarlayout" enum="webflowProgressBarType" batcheditable=false;

	property name="is_singleton" type="boolean" dbtype="boolean" required=true default=false indexes="singleton" batcheditable=false;
	property name="config"       type="string"  dbtype="text" batcheditable=false;
	property name="description"  type="string"  dbtype="text" renderer="plaintext" control="textarea" batcheditable=false;


	property name="timeout_in_minutes" type="numeric" dbtype="int" required=true default=20;
	property name="timeout_message"    type="string"  dbtype="text";
	property name="ineligble_message"  type="string"  dbtype="text";

	property name="steps" relationship="one-to-many" relationshipKey="webflow" relatedto="webflow_configuration_step";
	property name="step_count" type="numeric" formula="count( distinct ${prefix}steps.id )";

	property name="hide_from_widget" type="boolean" dbtype="boolean" required=false default=false;
	property name="is_admin_flow"    type="boolean" dbtype="boolean" required=false default=false indexes="adminflows" batcheditable=false;

	property name="active_instances_count"   type="numeric" formula="${prefix}id" renderer="webflowActiveInstancesCount";
	property name="timedout_instances_count" type="numeric" formula="${prefix}id" renderer="webflowTimedOutInstancesCount";
	property name="archived_instances_count" type="numeric" formula="${prefix}id" renderer="webflowArchivedInstancesCount";
	property name="completed_archived_count" type="numeric" formula="${prefix}id" renderer="webflowCompletedArchivedInstancesCount";
	property name="instance_completion_rate" type="numeric" formula="${prefix}id" renderer="webflowInstancesCompletionRate";
}