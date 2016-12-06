/**
 * This service is deprecated. Use [[api-rulesengineconditionservice]]
 * instead.
 *
 * @singleton
 * @presideservice
 * @autodoc
 *
 */
component displayName="RulesEngine Web Request Service" {

// CONSTRUCTOR
	/**
	 * @conditionService.inject    rulesEngineConditionService
	 *
	 */
	public any function init( required any conditionService) {
		_setConditionService( arguments.conditionService );

		return this;
	}


// PUBLIC API
	/**
	 * Deprecated. Use [[rulesengineconditionservice-evaluatecondition]] from
	 * the [[api-rulesengineconditionservice]] instead.
	 *
	 * @autodoc
	 * @conditionId.hint ID of the condition to evaluate
	 */
	public boolean function evaluateCondition( required string conditionId ) {
		return _getConditionService().evaluateCondition(
			  conditionId = arguments.conditionId
			, context     = "webrequest"
		);
	}

// GETTERS AND SETTERS
	private any function _getConditionService() {
		return _conditionService;
	}
	private void function _setConditionService( required any conditionService ) {
		_conditionService = arguments.conditionService;
	}

	private any function _getWebsiteLoginService() {
		return _websiteLoginService;
	}
	private void function _setWebsiteLoginService( required any websiteLoginService ) {
		_websiteLoginService = arguments.websiteLoginService;
	}

}