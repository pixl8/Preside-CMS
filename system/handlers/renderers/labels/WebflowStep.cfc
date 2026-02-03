/**
 * @feature webflow
 */
component {

	property name="webflowConfigurationService" inject="webflowConfigurationService";

	private array function _selectFields( event, rc, prc ) {
		return [
			    "webflow_configuration_step.step_id"
			  , "webflow.webflow_id"
		];
	}

	private string function _orderBy( event, rc, prc ) {
		return "webflow_configuration_step.step_id";
	}

	private string function _renderLabel( event, rc, prc ) {
		var stepId    = arguments.step_id;
		var webflowId = arguments.webflow_id ?: "";

		return webflowConfigurationService.getStepLabel( stepId, webflowId );
	}

}