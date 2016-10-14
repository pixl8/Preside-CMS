/**
 * Provides logic for processing web request condition
 * evaluations.
 * \n
 * See [[rules-engine]] for more details.
 *
 * @singleton
 * @presideservice
 * @autodoc
 *
 */
component displayName="RulesEngine Web Request Service" {

// CONSTRUCTOR
	/**
	 * @conditionService.inject rulesEngineConditionService
	 * @websiteLoginService.inject websiteLoginService
	 *
	 */
	public any function init( required any conditionService, required any websiteLoginService ) {
		_setConditionService( arguments.conditionService );
		_setWebsiteLoginService( arguments.websiteLoginService );

		return this;
	}


// PUBLIC API
	/**
	 * Evaluates the passed condition (id) in the 'webrequest'
	 * context, adding information about the request into the
	 * payload.
	 *
	 * @autodoc
	 * @conditionId.hint ID of the condition to evaluate
	 */
	public boolean function evaluateCondition( required string conditionId ) {
		var event   = $getRequestContext();
		var payload = {
			  page = event.getValue( name="presidePage", defaultValue={}, private=true )
			, user = _getWebsiteLoginService().getLoggedInUserDetails()
		};

		return _getConditionService().evaluateCondition(
			  conditionId = arguments.conditionId
			, context     = "webrequest"
			, payload     = payload
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