/**
 * @feature   cfflow
 * @nolabel   true
 * @versioned false
 * @tablePrefix ""
 * @useCache    false
 */
component {
	property name="instance" relationship="many-to-one" relatedto="cfflow_workflow_instance" required=true uniqueindexes="instancestep|1" ondelete="cascade";

	property name="step"     type="string" dbtype="varchar" maxlength=100 required=true indexes="step"  uniqueindexes="instancestep|2";
	property name="status"   type="string" dbtype="varchar" maxlength=10  required=true indexes="status" enum="cfflowStepStatus";
}