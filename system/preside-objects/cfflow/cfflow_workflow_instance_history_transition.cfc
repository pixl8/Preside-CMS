/**
 * @feature   cfflow
 * @nolabel   true
 * @versioned false
 * @tablePrefix ""
 */
component {
	property name="history" relationship="many-to-one" relatedto="cfflow_workflow_instance_history" required=true ondelete="cascade";
	property name="step"       type="string" dbtype="varchar" maxlength=100 required=true indexes="step";
	property name="status"     type="string" dbtype="varchar" maxlength=10  required=true indexes="status" enum="cfflowStepStatus";
	property name="old_status" type="string" dbtype="varchar" maxlength=10  required=false indexes="oldstatus" enum="cfflowStepStatus" default="pending";
}