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
		var template = _getEmailTemplateService().getTemplate( arguments.templateId );
		if ( template.isEmpty() ) {
			return 0;
		}

		var recipientObject = _getEmailRecipientTypeService().getFilterObjectForRecipientType( template.recipient_type );
		if ( !recipientObject.len() ) {
			throw(
				  type    = "preside.mass.email.invalid.recipient.type"
				, message = "The template, [#arguments.templateId#], cannot be queued for mass sending because it's recipient type, [#template.recipient_type#], does not cite a filter object from which to draw the recipients"
			);
		}

		var dbAdapter    = $getPresideObjectService().getDbAdapterForObject( "email_mass_send_queue" );
		var nowFunction  = dbAdapter.getNowFunctionSql();

		var extraFilters = getFiltersForSendLimits(
			  recipientType = template.recipient_type
			, sendLimit     = template.sending_limit
			, unit          = template.sending_limit_unit
			, measure       = template.sending_limit_measure
		);
		if ( template.recipient_filter.len() ) {
			var filterExpression = _getRulesEngineFilterService().getExpressionArrayForSavedFilter( template.recipient_filter );
			var recipientFilter  = _getRulesEngineFilterService().prepareFilter(
				  objectName      = recipientObject
				, expressionArray = filterExpression
			);
			extraFilters.append( recipientFilter );
		}

		return $getPresideObject( "email_mass_send_queue" ).insertDataFromSelect(
			  fieldList = [ "recipient", "template", "datecreated", "datemodified" ]
			, selectDataArgs = {
				  objectName   = recipientObject
				, selectFields = [ dbAdapter.escapeEntity( "#recipientObject#.id" ), ":template", nowFunction, nowFunction ]
				, filterParams = { template = { type="cf_sql_varchar", value=arguments.templateId } }
				, extraFilters = extraFilters
			  }
		);
	}

	/**
	 * Returns an array of prepared filters for the given
	 * templates recipient type + sending limits.
	 *
	 */
	public array function getFiltersForSendLimits() {
		// stubbed
		return [];
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