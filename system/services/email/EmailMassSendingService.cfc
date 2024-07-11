/**
 * Provides logic for sending out email en-masse.
 *
 * @autodoc        true
 * @singleton      true
 * @presideService true
 * @feature        customEmailTemplates
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
	 * @rulesEngineFilterService.inject  featureInjector:rulesEngine:rulesEngineFilterService
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
	public void function processQueue() {
		var rateLimit      = Val( $getPresideSetting( "email", "ratelimit", 100 ) );
		var processedCount = 0;
		var queuedEmail    = "";
		var emailService   = _getEmailService();
		var poService       = $getPresideObjectService();

		do {
			queuedEmail = getNextQueuedEmail();

			if ( !queuedEmail.count() ) {
				break;
			}

			try {
				emailService.send(
					  template    = queuedEmail.template
					, recipientId = queuedEmail.recipient
				);

			} catch ( Any e ) {
				$raiseError( e );
			}

			removeFromQueue( queuedEmail.id );
			if ( !processedCount mod 10 ) {
				poService.clearRelatedCaches( "email_mass_send_queue" );
			}
		} while( ++processedCount < rateLimit && !$isInterrupted() );

		if ( processedCount ) {
			poService.clearRelatedCaches( "email_mass_send_queue" );
		}
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

		var poService     = $getPresideObjectService();
		var dbAdapter     = poService.getDbAdapterForObject( "email_mass_send_queue" );
		var nowFunction   = dbAdapter.getNowFunctionSql();
		var idField       = "#recipientObject#.#poService.getIdField( recipientObject )#";
		var extraFilters  = getTemplateRecipientFilters( arguments.templateId );
		var inQueueFilter = _getDuplicateCheckFilter( recipientObject, arguments.templateId );
		var batchedSets   = [];
		var records       = "";
		var pageSize      = 100;
		var queuedCount   = 0;
		var filter        = "";
		var filterParams  = {};

		/**
		 * We used to do a single insertDataFromSelect() using the dynamic filters
		 * we prepared. However, for some scenarios, this is impossibly slow
		 * due to the way in which (insert into select) statements work in dbms's.
		 *
		 * Instead, we are batching out the ids of the recipients we want to send
		 * to and inserting that way. A little less elegent, but will perform well
		 * in all scenarios.
		 *
		 */
		do {
			records = poService.selectData(
				  objectName   = recipientObject
				, selectFields = [ "#idField# as id" ]
				, filter       = filter
				, filterParams = filterParams
				, extraFilters = extraFilters
				, orderBy      = idField
				, distinct     = true
				, maxRows      = pageSize
				, useCache     = false
			);

			if ( records.recordCount ) {
				ArrayAppend( batchedSets, ValueArray( records.id ) );

				filter = "#idField# > :#idField#";
				filterParams[ idField ] = records.id[ records.recordCount ];
			}
		} while( records.recordCount == pageSize );

		for( var batch in batchedSets ) {
			queuedCount += poService.insertDataFromSelect(
				  objectName = "email_mass_send_queue"
				, fieldList = [ "recipient", "template", "datecreated", "datemodified" ]
				, selectDataArgs = {
					  objectName   = recipientObject
					, selectFields = [ idField, ":template", nowFunction, nowFunction ]
					, filterParams = { template = { type="cf_sql_varchar", value=arguments.templateId } }
					, extraFilters = [ { filter={ "#idField#"=batch } }, inQueueFilter ]
				  }
			);
		}
		return queuedCount;
	}

	/**
	 * Returns an array of filters to be used when queueing or displaying
	 * the recipients for mass sending an email
	 *
	 * @autodoc         true
	 * @templateId      ID of the template whose filters you are to get
	 * @hideAlreadySent Whether or not to filter out recipients that have reached sending limits
	 */
	public array function getTemplateRecipientFilters( required string templateId, boolean hideAlreadySent=true ) {
		var template = _getEmailTemplateService().getTemplate( arguments.templateId );
		if ( template.isEmpty() ) {
			return [];
		}

		var recipientObject = _getEmailRecipientTypeService().getFilterObjectForRecipientType( template.recipient_type );
		if ( !recipientObject.len() ) {
			return [];
		}
		var extraFilters = arguments.hideAlreadySent ? getFiltersForSendLimits(
			  templateId    = arguments.templateId
			, recipientType = template.recipient_type
			, sendLimit     = template.sending_limit
			, unit          = template.sending_limit_unit
			, measure       = template.sending_limit_measure
		) : [];

		if ( $isFeatureEnabled( "rulesEngine" ) ) {
			var blueprintFilter = template.blueprint_filter ?: "";
			if ( Len( blueprintFilter ) ) {
				var filterExpression = _getRulesEngineFilterService().getExpressionArrayForSavedFilter( template.blueprint_filter );
				var recipientFilter  = _getRulesEngineFilterService().prepareFilter(
					  objectName      = recipientObject
					, expressionArray = filterExpression
				);
				extraFilters.append( recipientFilter );
			}
			if ( Len( Trim( template.recipient_filter ?: "" ) ) ) {
				var isSegmentationFilter = _getRulesEngineFilterService().isSegmentationFilter( filterid=template.recipient_filter );

				if ( isSegmentationFilter ) {
					var recipientFilter = _getRulesEngineFilterService().prepareSegmentationFilter(
						  objectName = recipientObject
						, filterId   = template.recipient_filter
					);
				} else {
					var filterExpression = _getRulesEngineFilterService().getExpressionArrayForSavedFilter( template.recipient_filter );
					var recipientFilter  = _getRulesEngineFilterService().prepareFilter(
						  objectName      = recipientObject
						, expressionArray = filterExpression
					);
				}

				ArrayAppend( extraFilters, recipientFilter )
			}
		}

		extraFilters.append( _getDuplicateCheckFilter( recipientObject, arguments.templateId ) );

		var interceptorArgs = {
			  extraFilters    = extraFilters
			, templateId      = arguments.templateId
			, recipientObject = recipientObject
			, template        = template
		};
		$announceInterception( "onPrepareEmailTemplateRecipientFilters", interceptorArgs );

		return interceptorArgs.extraFilters;
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
			, useCache        = false
		);
	}

	/**
	 * Automatically queues any scheduled templates that are due
	 * for sending.
	 *
	 * @autodoc true
	 */
	public numeric function autoQueueScheduledSendouts() {
		var templateService   = _getEmailTemplateService();
		var oneTimeTemplates  = templateService.listDueOneTimeScheduleTemplates();
		var repeatedTemplates = templateService.listDueRepeatedScheduleTemplates();
		var totalQueued       = 0;

		for( var oneTimeTemplate in oneTimeTemplates ){
			try {
				totalQueued += queueSendout( oneTimeTemplate );
				templateService.updateScheduledSendFields( templateId=oneTimeTemplate, markAsSent=true );
			}
			catch( any e ) {
				$raiseError( e );
			}
		}

		for( var repeatedTemplate in repeatedTemplates ){
			try {
				totalQueued += queueSendout( repeatedTemplate );
				templateService.updateScheduledSendFields( templateId=repeatedTemplate );
			}
			catch( any e ) {
				$raiseError( e );
			}
		}

		return totalQueued;
	}

	/**
	 * Automatically requeues any emails that were marked as sending but have
	 * not then completed. This may occur due to a server restart during sending, etc.
	 *
	 * @autodoc true
	 */
	public numeric function requeueHungEmails() {
		return $getPresideObject( "email_mass_send_queue" ).updateData(
			  data         = { status="queued" }
			, filter       = "status = :status and datemodified < :datemodified"
			, filterParams = { status="sending", datemodified=DateAdd( "h", -1, Now() ) }
		);
	}

	/**
	 * Returns the next queued email ready for sending.
	 *
	 * @autodoc true
	 */
	public struct function getNextQueuedEmail() {
		var takenByOtherProcess = false;
		var attempts            = 0;

		do {
			// sleep random ms to help with multithreads
			// not selecting at the same time
			sleep( randRange( 1, 10 ) );

			var queueDao    = $getPresideObject( "email_mass_send_queue" );
			var queuedEmail = queueDao.selectData(
				  selectFields = [ "id", "recipient", "template" ]
				, filter       = "status is null or status = :status"
				, filterParams = { status="queued" }
				, orderby      = "datecreated"
				, maxRows      = 1
			);

			if ( !queuedEmail.recordCount ) {
				return {};
			}

			takenByOtherProcess = !queueDao.updateData(
				  filter       = "id = :id and ( status is null or status = :status )"
				, filterParams = { id=queuedEmail.id, status="queued" }
				, data         = { status = "sending" }
			);

			if ( !takenByOtherProcess ) {
				for( var q in queuedEmail ) {
					return q;
				}
			}
		} while( takenByOtherProcess && ++attempts<=10 );

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
		var recipientIdField = $getPresideObjectService().getIdField( recipientObject );
		var dbAdapter        = $getPresideObjectService().getDbAdapterForObject( "email_template_send_log" );
		var recipientLogFk   = dbAdapter.escapeEntity( _getEmailRecipientTypeService().getRecipientIdLogPropertyForRecipientType( arguments.recipientType ) );
		var outerJoin        = $obfuscateSqlForPreside( "#recipientLogFk# = #recipientObject#.#recipientIdField#" );
		var filter           = "#outerJoin# and email_template = :email_template";
		var params           = { email_template=arguments.templateId };

		if ( sendLimit == "limited" ) {
			filter &= " and sent_date > :sent_date";
			params.sent_date = _getLimitDate( unit=arguments.unit, measure=Val( arguments.measure ) );
		}

		var subquery = $getPresideObject( "email_template_send_log" ).selectData(
			  selectFields        = [ "1" ]
			, filter              = filter
			, filterParams        = params
			, getSqlAndParamsOnly = true
			, formatSqlParams     = true
		);

		return [{
			  filter       = $obfuscateSqlForPreside( "not exists (#subquery.sql#)" )
			, filterParams = subquery.params
		}];
	}


// PRIVATE HELPERS
	private date function _getLimitDate( required string unit, required numeric measure ) {
		if ( !StructKeyExists( _timeUnitToCfMapping, arguments.unit ) ) {
			return '1900-01-01';
		}

		return DateAdd( _timeUnitToCfMapping[ arguments.unit ], 0-arguments.measure, Now() );
	}

	private struct function _getDuplicateCheckFilter( required string recipientObject, required string templateId ) {
		var recipientIdField = $getPresideObjectService().getIdField( arguments.recipientObject );
		var outerJoin        = $obfuscateSqlForPreside( "recipient = #arguments.recipientObject#.#recipientIdField#" );
		var sqlAndParams = $getPresideObject( "email_mass_send_queue" ).selectData(
			  selectFields        = [ "1" ]
			, filter              = "#outerJoin# and template = :template"
			, filterParams        = { template=arguments.templateId }
			, getSqlAndParamsOnly = true
			, formatSqlParams     = true
		);

		return {
			  filter = $obfuscateSqlForPreside( "not exists (#sqlAndParams.sql#)" )
			, filterParams = sqlAndParams.params
		};
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