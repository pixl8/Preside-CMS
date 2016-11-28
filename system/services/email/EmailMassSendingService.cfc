/**
 * Provides logic for sending out email en-masse.
 *
 * @autodoc        true
 * @singleton      true
 * @presideService true
 *
 */
component {

// CONSTRUCTOR
	/**
	 * @emailTemplateService.inject      emailTemplateService
	 * @emailRecipientTypeService.inject emailRecipientTypeService
	 * @rulesEngineFilterService.inject  rulesEngineFilterService
	 *
	 */
	public any function init(
		  required any emailTemplateService
		, required any emailRecipientTypeService
		, required any rulesEngineFilterService
	) {
		_setEmailTemplateService( arguments.emailTemplateService );
		_setEmailRecipientTypeService( arguments.emailRecipientTypeService );
		_setRulesEngineFilterService( arguments.rulesEngineFilterService );

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Takes a template and queues it for send-out based
	 * on the template's, recipient type, filters + sending
	 * limitations.
	 *
	 * @autodoc         true
	 * @templateId.hint ID of the template to queue
	 */
	public numeric function queueSendout( required string templateId ) {
		var template        = _getEmailTemplateService().getTemplate( arguments.templateId );
		var recipientObject = _getEmailRecipientTypeService().getFilterObjectForRecipientType( template.recipient_type );
		var filterExpression = _getRulesEngineFilterService().getExpressionArrayForSavedFilter( template.recipient_filter );
		var dbAdapter        = $getPresideObjectService().getDbAdapterForObject( "email_mass_send_queue" );
		var nowFunction      = dbAdapter.getNowFunctionSql();
		var recipientFilter  = _getRulesEngineFilterService().prepareFilter(
			  objectName      = recipientObject
			, expressionArray = filterExpression
		);

		return $getPresideObject( "email_mass_send_queue" ).insertDataFromSelect(
			  fieldList = [ "recipient", "template", "datecreated", "datemodified" ]
			, selectDataArgs = {
				  objectName   = recipientObject
				, selectFields = [ dbAdapter.escapeEntity( "#recipientObject#.id" ), ":template", nowFunction, nowFunction ]
				, filterParams = { template = { type="cf_sql_varchar", value=arguments.templateId } }
				, extraFilters = [ recipientFilter ]
			  }
		);
	}

// PRIVATE HELPERS

// GETTERS AND SETTERS
	private any function _getEmailTemplateService() {
		return _emailTemplateService;
	}
	private void function _setEmailTemplateService( required any emailTemplateService ) {
		_emailTemplateService = arguments.emailTemplateService;
	}

	private any function _getEmailRecipientTypeService() {
		return _emailRecipientTypeService;
	}
	private void function _setEmailRecipientTypeService( required any emailRecipientTypeService ) {
		_emailRecipientTypeService = arguments.emailRecipientTypeService;
	}

	private any function _getRulesEngineFilterService() {
		return _rulesEngineFilterService;
	}
	private void function _setRulesEngineFilterService( required any rulesEngineFilterService ) {
		_rulesEngineFilterService = arguments.rulesEngineFilterService;
	}
}