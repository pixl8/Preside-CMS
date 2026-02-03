/**
 * @feature        cfflow
 * @presideService true
 * @singleton      true
 */
component implements="preside.system.modules.cfflow.models.implementation.interfaces.IWorkflowCondition" {

	public any function init() {
		return;
	}

	public boolean function evaluate( required WorkflowInstance wfInstance, required struct args ){
		return $isWebsiteUserLoggedIn();
	}

}