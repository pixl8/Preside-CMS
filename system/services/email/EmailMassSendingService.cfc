/**
 * Provides logic for sending out email en-masse.
 *
 * @autodoc        true
 * @singleton      true
 * @presideService true
 *
 */
component {

	_timeUnitToCfMapping = {
		  second  = "s"
		, minute  = "n"
		, hour    = "h"
		, day     = "d"
		, week    = "ww"
		, month   = "m"
		, quarter = "q"
		, year    = "yyyy"
	};

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
			  templateId    = arguments.templateId
			, recipientType = template.recipient_type
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

		extraFilters.append( _getDuplicateCheckFilter( recipientObject, dbAdapter ) );

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
	 * Returns the next queued email ready for sending.
	 *
	 * @autodoc true
	 */
	public struct function getNextQueuedEmail() {
		var queuedEmail = $getPresideObject( "email_mass_send_queue" ).selectData(
			  selectFields = [ "id", "recipient", "template" ]
			, orderby      = "id"
			, maxRows      = 1
		);

		for( var q in queuedEmail ) {
			return q;
		}

		return {};
	}

	/**
	 * Removes the given queued email (by id) from the queue.
	 *
	 * @autodoc true
	 * @id.hint ID of the queued email
	 */
	public numeric function removeFromQueue( required string id ) {
		return $getPresideObject( "email_mass_send_queue" ).deleteData( id=arguments.id );
	}

	/**
	 * Returns an array of prepared filters for the given
	 * templates recipient type + sending limits.
	 *
	 */
	public array function getFiltersForSendLimits(
		  required string templateId
		, required string recipientType
		, required string sendLimit
		,          string unit
		,          string measure
	) {
		if ( sendLimit == "none" ) {
			return [];
		}

		var recipientObject  = _getEmailRecipientTypeService().getFilterObjectForRecipientType( arguments.recipientType );
		var dbAdapter        = $getPresideObjectService().getDbAdapterForObject( "email_template_send_log" );
		var recipientLogFk   = dbAdapter.escapeEntity( _getEmailRecipientTypeService().getRecipientIdLogPropertyForRecipientType( arguments.recipientType ) );
		var lastSentSubquery = $getPresideObject( "email_template_send_log" ).selectData(
			  selectFields        = [ "Max( #dbAdapter.escapeEntity( 'sent_date' )# ) as sent_date", "#recipientLogFk# as recipient" ]
			, groupBy             = recipientLogFk
			, filter              = { email_template=arguments.templateId }
			, getSqlAndParamsOnly = true
		);
		var filter = {
			  filter = "send_limit_check.recipient is null"
			, filterParams = {}
			, extraJoins = []
		};

		filter.extraJoins.append({
			  type           = "left"
			, subQuery       = lastSentSubquery.sql
			, subQueryAlias  = "send_limit_check"
			, subQueryColumn = "recipient"
			, joinToTable    = recipientObject
			, joinToColumn   = "id"
		});

		for( var param in lastSentSubquery.params ) {
			filter.filterParams[ param.name ] = Duplicate( param );
			filter.filterParams[ param.name ].delete( "name" );
		}

		if ( sendLimit == "limited" ) {
			filter.filter = "( #filter.filter# or send_limit_check.sent_date < :send_limit_check_date )";
			filter.filterParams.send_limit_check_date = { type="cf_sql_timestamp", value=_getLimitDate( unit=arguments.unit, measure=Val( arguments.measure ) ) };
		}

		return [ filter ];

	}

// PRIVATE HELPERS
	private date function _getLimitDate( required string unit, required numeric measure ) {
		if ( !_timeUnitToCfMapping.keyExists( arguments.unit ) ) {
			return '1900-01-01';
		}

		return DateAdd( _timeUnitToCfMapping[ arguments.unit ], 0-arguments.measure, Now() );
	}

	private struct function _getDuplicateCheckFilter( required string recipientObject, required any dbAdapter ) {
		var filter = { filter="already_queued_check.recipient is null", filterParams={} };
		var subQuery = $getPresideObject( "email_mass_send_queue" ).selectData(
			  selectFields        = [ "recipient", "template" ]
			, getSqlAndParamsOnly = true
		).sql;

		filter.extraJoins = [{
			  type              = "left"
			, subQuery          = subQuery
			, subQueryAlias     = "already_queued_check"
			, subQueryColumn    = "recipient"
			, joinToTable       = arguments.recipientObject
			, joinToColumn      = "id"
			, additionalClauses = "template = :template"
		} ];

		return filter;
	}

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