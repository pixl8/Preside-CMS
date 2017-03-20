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
	 * @emailService.inject              emailService
	 * @rulesEngineFilterService.inject  rulesEngineFilterService
	 *
	 */
	public any function init(
		  required any emailTemplateService
		, required any emailRecipientTypeService
		, required any emailService
		, required any rulesEngineFilterService
	) {
		_setEmailTemplateService( arguments.emailTemplateService );
		_setEmailRecipientTypeService( arguments.emailRecipientTypeService );
		_setRulesEngineFilterService( arguments.rulesEngineFilterService );
		_setEmailService( arguments.emailService );

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Processes the queue by sending out emails from the queue. Processes
	 * up to a maximum number of emails as set in email center general settings
	 * (preside system setting `email.ratelimit`).
	 *
	 * @autodoc true
	 */
	public boolean function processQueue( any logger ) {
		autoQueueScheduledSendouts( logger ?: NullValue() )

		var rateLimit      = Val( $getPresideSetting( "email", "ratelimit", 100 ) );
		var processedCount = 0;
		var queuedEmail    = "";
		var emailService   = _getEmailService();
		var canLog         = arguments.keyExists( "logger" );
		var canInfo        = canLog && logger.canInfo();
		var canError       = canLog && logger.canError();

		do {
			queuedEmail = getNextQueuedEmail();

			if ( !queuedEmail.count() ) {
				if ( canInfo ) { logger.info( "The batch sending queue is empty!" ); }
				break;
			}

			if ( canInfo ) { logger.info( "Sending email template, [#queuedEmail.template#], to recipient, [#queuedEmail.recipient#]" ); }

			var result = emailService.send(
				  template    = queuedEmail.template
				, recipientId = queuedEmail.recipient
			);

			if ( !result && canError ) {
				logger.error( "Sending failed. See email sending logs and error logs for detail." );
			}

			removeFromQueue( queuedEmail.id );
		} while( ++processedCount < rateLimit );

		if ( canInfo ) { logger.info( "Done. Processed [#NumberFormat( processedCount )#] queued emails." ); }

		return true;
	}

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
				, message = "The template, [#arguments.templateId#], cannot be queued for mass sending because its recipient type, [#template.recipient_type#], does not cite a filter object from which to draw the recipients"
			);
		}

		var dbAdapter    = $getPresideObjectService().getDbAdapterForObject( "email_mass_send_queue" );
		var nowFunction  = dbAdapter.getNowFunctionSql();
		var extraFilters = getTemplateRecipientFilters( arguments.templateId );

		return $getPresideObject( "email_mass_send_queue" ).insertDataFromSelect(
			  fieldList = [ "recipient", "template", "datecreated", "datemodified" ]
			, selectDataArgs = {
				  objectName   = recipientObject
				, selectFields = [ dbAdapter.escapeEntity( "#recipientObject#.id" ), ":template", nowFunction, nowFunction ]
				, filterParams = { template = { type="cf_sql_varchar", value=arguments.templateId } }
				, extraFilters = extraFilters
				, distinct     = true
			  }
		);
	}

	/**
	 * Returns an array of filters to be used when queueing or displaying
	 * the recipients for mass sending an email
	 *
	 * @autodoc         true
	 * @templateId.hint ID of the template whose filters you are to get
	 */
	public array function getTemplateRecipientFilters( required string templateId ) {
		var template = _getEmailTemplateService().getTemplate( arguments.templateId );
		if ( template.isEmpty() ) {
			return [];
		}

		var recipientObject = _getEmailRecipientTypeService().getFilterObjectForRecipientType( template.recipient_type );
		if ( !recipientObject.len() ) {
			return [];
		}
		var extraFilters = getFiltersForSendLimits(
			  templateId    = arguments.templateId
			, recipientType = template.recipient_type
			, sendLimit     = template.sending_limit
			, unit          = template.sending_limit_unit
			, measure       = template.sending_limit_measure
		);
		var blueprintFilter = template.blueprint_filter ?: "";
		if ( blueprintFilter.len() ) {
			var filterExpression = _getRulesEngineFilterService().getExpressionArrayForSavedFilter( template.blueprint_filter );
			var recipientFilter  = _getRulesEngineFilterService().prepareFilter(
				  objectName      = recipientObject
				, expressionArray = filterExpression
			);
			extraFilters.append( recipientFilter );
		}
		if ( template.recipient_filter.len() ) {
			var filterExpression = _getRulesEngineFilterService().getExpressionArrayForSavedFilter( template.recipient_filter );
			var recipientFilter  = _getRulesEngineFilterService().prepareFilter(
				  objectName      = recipientObject
				, expressionArray = filterExpression
			);
			extraFilters.append( recipientFilter );
		}

		extraFilters.append( _getDuplicateCheckFilter( recipientObject, arguments.templateId ) );

		return extraFilters;
	}

	/**
	 * Gets a count of recipients that would be queued should the send be initiated now
	 *
	 * @autodoc         true
	 * @templateId.hint ID of the template whose filters you are to get
	 */
	public numeric function getTemplateRecipientCount( required string templateId ) {
		var template = _getEmailTemplateService().getTemplate( arguments.templateId );
		if ( template.isEmpty() ) {
			return 0;
		}

		var recipientObject = _getEmailRecipientTypeService().getFilterObjectForRecipientType( template.recipient_type );
		if ( !recipientObject.len() ) {
			return 0;
		}

		return $getPresideObject( recipientObject ).selectData(
			  selectFields    = [ "id" ]
			, extraFilters    = getTemplateRecipientFilters( arguments.templateId )
			, recordCountOnly = true
			, distinct        = true
		);
	}

	/**
	 * Automatically queues any scheduled templates that are due
	 * for sending.
	 *
	 * @autodoc true
	 */
	public numeric function autoQueueScheduledSendouts( any logger ) {
		var templateService   = _getEmailTemplateService();
		var oneTimeTemplates  = templateService.listDueOneTimeScheduleTemplates();
		var repeatedTemplates = templateService.listDueRepeatedScheduleTemplates();
		var totalQueued       = 0;
		var canLog            = arguments.keyExists( "logger" );
		var canInfo           = canLog && logger.canInfo();

		if ( canInfo ) {
			if ( oneTimeTemplates.len() ) {
				logger.info( "Queueing [#oneTimeTemplates.len()#] one time scheduled email template(s) for sending..." );
			}
			if ( repeatedTemplates.len() ) {
				logger.info( "Queueing [#repeatedTemplates.len()#] repeat scheduled email template(s) for sending..." );
			}
		}

		for( var oneTimeTemplate in oneTimeTemplates ){
			totalQueued += queueSendout( oneTimeTemplate );
			templateService.updateScheduledSendFields( templateId=oneTimeTemplate, markAsSent=true );
		}

		for( var repeatedTemplate in repeatedTemplates ){
			totalQueued += queueSendout( repeatedTemplate );
			templateService.updateScheduledSendFields( templateId=repeatedTemplate );
		}

		if ( canInfo && ( oneTimeTemplates.len() + repeatedTemplates.len() ) ) {
			logger.info( "[#NumberFormat( totalQueued )#] emails were queued to send" );
		}

		return totalQueued;
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

	private struct function _getDuplicateCheckFilter( required string recipientObject, required string templateId ) {
		var filter = { filter="already_queued_check.recipient is null", filterParams={ template={ type="cf_sql_varchar", value=templateId } } };
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

	private any function _getEmailService() {
		return _emailService;
	}
	private void function _setEmailService( required any emailService ) {
		_emailService = arguments.emailService;
	}

	private any function _getRulesEngineFilterService() {
		return _rulesEngineFilterService;
	}
	private void function _setRulesEngineFilterService( required any rulesEngineFilterService ) {
		_rulesEngineFilterService = arguments.rulesEngineFilterService;
	}
}