component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "queueSendout()", function(){
			it( "should insert data into the queue based on the filter, target object and limit rules of the supplied email template", function(){
				var service         = _getService();
				var templateId      = CreateUUId();
				var filterId        = CreateUUId();
				var recipientType   = "websiteUser";
				var recipientObject = "website_user";
				var expressionArray = [ CreateUUId() ];
				var preparedFilter  = { testFilter=CreateUUId() };
				var queuedCount     = 43958;
				var template        = {
					  recipient_type        = "websiteUser"
					, recipient_filter      = filterId
					, blueprint_filter      = ""
					, sending_limit         = "none"
					, sending_limit_unit    = ""
					, sending_limit_measure = ""
				};
				var dupeCheckFilter = _getDuplicateCheckFilter( recipientObject, templateId );

				mockEmailTemplateService.$( "getTemplate" ).$args( templateId ).$results( template );
				mockEmailRecipientTypeService.$( "getFilterObjectForRecipientType" ).$args( recipientType ).$results( recipientObject );
				mockRulesEngineFilterService.$( "getExpressionArrayForSavedFilter" ).$args( filterId ).$results( expressionArray );
				mockRulesEngineFilterService.$( "prepareFilter" ).$args( objectName=recipientObject, expressionArray=expressionArray ).$results( preparedFilter );
				service.$( "getFiltersForSendLimits", [] );
				mockDbAdapter.$( "escapeEntity" ).$args( "#recipientObject#.id" ).$results( "`#recipientObject#`.`id`" );

				mockQueueDao.$( "insertDataFromSelect" ).$args(
					  fieldList      = [ "recipient", "template", "datecreated", "datemodified" ]
					, selectDataArgs = {
						  selectFields = [ "`#recipientObject#`.`id`", ":template", "nowwweee()", "nowwweee()" ]
						, objectName   = recipientObject
						, extraFilters = [ preparedFilter, dupeCheckFilter ]
						, filterParams = { template = { type="cf_sql_varchar", value=templateId } }
						, distinct     = true
					}
				).$results( queuedCount );

				expect( service.queueSendout( templateId ) ).toBe( queuedCount );
			} );

			it( "should return zero and do nothing when the template is not found", function(){
				var service    = _getService();
				var templateId = CreateUUId();

				mockQueueDao.$( "insertDataFromSelect", 0 );
				mockEmailTemplateService.$( "getTemplate" ).$args( templateId ).$results( {} );

				expect( service.queueSendout( templateId ) ).toBe( 0 );
				expect( mockQueueDao.$callLog().insertDataFromSelect.len() ).toBe( 0 );
			} );

			it( "should throw an informative error when the template's recipient type does not have a core filter object", function(){
				var service         = _getService();
				var templateId      = CreateUUId();
				var recipientType   = "anonymous";
				var recipientObject = "";
				var errorThrown     = false;
				var template        = {
					  recipient_type        = recipientType
					, recipient_filter      = ""
					, blueprint_filter      = ""
					, sending_limit         = "none"
					, sending_limit_unit    = ""
					, sending_limit_measure = ""
				};

				mockEmailTemplateService.$( "getTemplate" ).$args( templateId ).$results( template );
				mockEmailRecipientTypeService.$( "getFilterObjectForRecipientType" ).$args( recipientType ).$results( recipientObject );

				try {
					service.queueSendout( templateId );
				} catch( "preside.mass.email.invalid.recipient.type" e ) {
					expect( e.message ).toBe( "The template, [#templateId#], cannot be queued for mass sending because its recipient type, [#recipientType#], does not cite a filter object from which to draw the recipients" );
					errorThrown = true;
				}

				expect( errorThrown ).toBe( true );
			} );

			it( "should not prepare a filter if the template does not have a configured filter", function(){
				var service         = _getService();
				var templateId      = CreateUUId();
				var recipientType   = "websiteUser";
				var recipientObject = "website_user";
				var expressionArray = [ CreateUUId() ];
				var preparedFilter  = { testFilter=CreateUUId() };
				var queuedCount     = 3877;
				var template        = {
					  recipient_type        = recipientType
					, recipient_filter      = ""
					, blueprint_filter      = ""
					, sending_limit         = "none"
					, sending_limit_unit    = ""
					, sending_limit_measure = ""
				};
				var dupeCheckFilter = _getDuplicateCheckFilter( recipientObject, templateId );

				service.$( "getFiltersForSendLimits", [] );
				mockEmailTemplateService.$( "getTemplate" ).$args( templateId ).$results( template );
				mockEmailRecipientTypeService.$( "getFilterObjectForRecipientType" ).$args( recipientType ).$results( recipientObject );
				mockRulesEngineFilterService.$( "getExpressionArrayForSavedFilter", [] );
				mockRulesEngineFilterService.$( "prepareFilter", {} );

				mockDbAdapter.$( "escapeEntity" ).$args( "#recipientObject#.id" ).$results( "`#recipientObject#`.`id`" );

				mockQueueDao.$( "insertDataFromSelect" ).$args(
					  fieldList      = [ "recipient", "template", "datecreated", "datemodified" ]
					, selectDataArgs = {
						  selectFields = [ "`#recipientObject#`.`id`", ":template", "nowwweee()", "nowwweee()" ]
						, objectName   = recipientObject
						, extraFilters = [ dupeCheckFilter ]
						, filterParams = { template = { type="cf_sql_varchar", value=templateId } }
						, distinct     = true
					}
				).$results( queuedCount )

				expect( service.queueSendout( templateId ) ).toBe( queuedCount );
				expect( mockRulesEngineFilterService.$callLog().getExpressionArrayForSavedFilter.len() ).toBe( 0 );
				expect( mockRulesEngineFilterService.$callLog().prepareFilter.len() ).toBe( 0 );
			} );

			it( "should add filters from the 'getFiltersForSendLimits()' method to the the select data filters", function(){
				var service         = _getService();
				var templateId      = CreateUUId();
				var recipientType   = "websiteUser";
				var recipientObject = "website_user";
				var expressionArray = [ CreateUUId() ];
				var preparedFilter  = { testFilter=CreateUUId() };
				var queuedCount     = 3877;
				var template        = {
					  recipient_type        = recipientType
					, recipient_filter      = ""
					, sending_limit         = "limited"
					, sending_limit_unit    = "10"
					, sending_limit_measure = "days"
				};
				var limitFilters = [ { blah=CreateUUId() }, { test=CreateUUId() } ];
				var extraFilters = Duplicate( limitFilters );

				extraFilters.append( _getDuplicateCheckFilter( recipientObject, templateId ) );

				service.$( "getFiltersForSendLimits" ).$args(
					  templateId    = templateId
					, recipientType = recipientType
					, sendLimit     = template.sending_limit
					, unit          = template.sending_limit_unit
					, measure       = template.sending_limit_measure
				).$results( limitFilters );
				mockEmailTemplateService.$( "getTemplate" ).$args( templateId ).$results( template );
				mockEmailRecipientTypeService.$( "getFilterObjectForRecipientType" ).$args( recipientType ).$results( recipientObject );

				mockDbAdapter.$( "escapeEntity" ).$args( "#recipientObject#.id" ).$results( "`#recipientObject#`.`id`" );

				mockQueueDao.$( "insertDataFromSelect" ).$args(
					  fieldList      = [ "recipient", "template", "datecreated", "datemodified" ]
					, selectDataArgs = {
						  selectFields = [ "`#recipientObject#`.`id`", ":template", "nowwweee()", "nowwweee()" ]
						, objectName   = recipientObject
						, extraFilters = extraFilters
						, filterParams = { template = { type="cf_sql_varchar", value=templateId } }
						, distinct     = true
					}
				).$results( queuedCount )

				expect( service.queueSendout( templateId ) ).toBe( queuedCount );
			} );
		} );

		describe( "getFiltersForSendLimits()", function(){
			it( "should return an empty array when limit = 'none'", function(){
				var service = _getService();

				expect( service.getFiltersForSendLimits(
					  templateId    = CreateUUId()
					, recipientType = "whatever"
					, sendLimit     = "none"
					, unit          = ""
					, measure       = ""
				) ).toBe( [] );
			} );

			it( "should return a filter using a subquery join on the email log table to rule out previous recipients, when sendLimit = 'once'", function(){
				var service         = _getService();
				var templateId      = CreateUUId();
				var recipientType   = "whatever";
				var recipientObject = "whatever_test";
				var recipientFk     = "blah";
				var subquery        = "select * from blah";

				mockLogDao.$( "selectData" ).$args(
					  selectFields        = [ "Max( `sent_date` ) as sent_date", "`#recipientFk#` as recipient" ]
					, groupBy             = "`#recipientFk#`"
					, filter              = { email_template=templateId }
					, getSqlAndParamsOnly = true
				).$results( { sql=subquery, params=[ { name="email_template", type="cf_sql_varchar", value=templateId } ] } );

				mockDbAdapter.$( "escapeEntity" ).$args( recipientFk ).$results( "`#recipientFk#`" );
				mockDbAdapter.$( "escapeEntity" ).$args( "sent_date" ).$results( "`sent_date`" );

				mockEmailRecipientTypeService.$( "getRecipientIdLogPropertyForRecipientType" ).$args( recipientType ).$results( recipientFk );
				mockEmailRecipientTypeService.$( "getFilterObjectForRecipientType" ).$args( recipientType ).$results( recipientObject );
				expect( service.getFiltersForSendLimits(
					  templateId    = templateId
					, recipientType = recipientType
					, sendLimit     = "once"
					, unit          = ""
					, measure       = ""
				) ).toBe( [ { filter="send_limit_check.recipient is null", filterParams={ email_template={ type="cf_sql_varchar", value=templateId } }, extraJoins=[ {
					  type           = "left"
					, subQuery       = subquery
					, subQueryAlias  = "send_limit_check"
					, subQueryColumn = "recipient"
					, joinToTable    = recipientObject
					, joinToColumn   = "id"
				} ] } ] );
			} );

			it( "should return a filter using a subquery join on the email log table to rule out recent previous recipients, when sendLimit = 'limited'", function(){
				var service         = _getService();
				var templateId      = CreateUUId();
				var recipientType   = "whatever";
				var recipientObject = "whatever_test";
				var recipientFk     = "blah";
				var subquery        = "select * from blah";
				var someDate        = Now();

				service.$( "_getLimitDate" ).$args( unit="week", measure=3 ).$results( someDate );
				mockLogDao.$( "selectData" ).$args(
					  selectFields        = [ "Max( `sent_date` ) as sent_date", "`#recipientFk#` as recipient" ]
					, groupBy             = "`#recipientFk#`"
					, filter              = { email_template=templateId }
					, getSqlAndParamsOnly = true
				).$results( { sql=subquery, params=[ { name="email_template", type="cf_sql_varchar", value=templateId } ] } );

				mockDbAdapter.$( "escapeEntity" ).$args( recipientFk ).$results( "`#recipientFk#`" );
				mockDbAdapter.$( "escapeEntity" ).$args( "sent_date" ).$results( "`sent_date`" );

				mockEmailRecipientTypeService.$( "getRecipientIdLogPropertyForRecipientType" ).$args( recipientType ).$results( recipientFk );
				mockEmailRecipientTypeService.$( "getFilterObjectForRecipientType" ).$args( recipientType ).$results( recipientObject );
				expect( service.getFiltersForSendLimits(
					  templateId    = templateId
					, recipientType = recipientType
					, sendLimit     = "limited"
					, unit          = "week"
					, measure       = 3
				) ).toBe( [ { filter="( send_limit_check.recipient is null or send_limit_check.sent_date < :send_limit_check_date )", filterParams={ email_template={ type="cf_sql_varchar", value=templateId }, send_limit_check_date={ type="cf_sql_timestamp", value=someDate } }, extraJoins=[ {
					  type           = "left"
					, subQuery       = subquery
					, subQueryAlias  = "send_limit_check"
					, subQueryColumn = "recipient"
					, joinToTable    = recipientObject
					, joinToColumn   = "id"
				} ] } ] );
			} );
		} );

		describe( "getNextQueuedEmail()", function(){
			it( "should return the first queued email from the email queue table", function(){
				var service     = _getService();
				var id          = 49;
				var recipientId = CreateUUId();
				var templateId  = CreateUUId()
				var dummyRecord = QueryNew( "id,recipient,template", "int,varchar,varchar", [ [ id, recipientId, templateId ] ] );

				mockQueueDao.$( "selectData" ).$args(
					  selectFields = [ "id", "recipient", "template" ]
					, orderBy      = "datecreated"
					, filter       = "status is null or status = :status"
					, filterParams = { status="queued" }
					, maxRows      = 1
				).$results( dummyRecord );
				mockQueueDao.$( "updateData", 1 )

				expect( service.getNextQueuedEmail() ).toBe( { id=id, recipient=recipientId, template=templateId } );
			} );

			it( "should return an empty struct when no record is returned", function(){
				var service     = _getService();
				var dummyRecord = QueryNew( "id,recipient,template" );

				mockQueueDao.$( "selectData" ).$args(
					  selectFields = [ "id", "recipient", "template" ]
					, orderBy      = "datecreated"
					, filter       = "status is null or status = :status"
					, filterParams = { status="queued" }
					, maxRows      = 1
				).$results( dummyRecord );

				expect( service.getNextQueuedEmail() ).toBe( {} );
			} );

			it( "should update the status of the queued email to ensure no other processes attempt to process the same email", function(){
				var service     = _getService();
				var id          = 49;
				var recipientId = CreateUUId();
				var templateId  = CreateUUId()
				var dummyRecord = QueryNew( "id,recipient,template", "int,varchar,varchar", [ [ id, recipientId, templateId ] ] );

				mockQueueDao.$( "selectData" ).$args(
					  selectFields = [ "id", "recipient", "template" ]
					, orderBy      = "datecreated"
					, filter       = "status is null or status = :status"
					, filterParams = { status="queued" }
					, maxRows      = 1
				).$results( dummyRecord );
				mockQueueDao.$( "updateData", 1 )

				expect( service.getNextQueuedEmail() ).toBe( { id=id, recipient=recipientId, template=templateId } );

				var updateCallLog = mockQueueDao.$callLog().updateData;

				expect( updateCallLog.len()  ).toBe( 1 );
				expect( updateCallLog[ 1 ]  ).toBe( {
					  filter       = "id = :id and ( status is null or status = :status )"
					, filterParams = { id=id, status="queued" }
					, data         = { status = "sending" }
				} );

			} );
		} );

		describe( "removeFromQueue()", function(){
			it( "should delete the given queue record", function(){
				var service      = _getService();
				var queueId      = CreateUUId();
				var randomNumber = Round( Rand() * 1000 );

				mockQueueDao.$( "deleteData" ).$args( id=queueId ).$results( randomNumber );

				expect( service.removeFromQueue( queueId ) ).toBe( randomNumber );
			} );
		} );

		describe( "processQueue()", function(){
			it( "should repeatedly retrieve emails from the queue and send them, stopping when the rate limit is reached", function(){
				var service   = _getService();
				var rateLimit = Round( rand() * 100 ) + 1;
				var emails    = [];

				for( var i=1; i<=rateLimit; i++ ) {
					emails.append({
						  id        = CreateUUId()
						, template  = CreateUUId()
						, recipient = CreateUUId()
					});
				}

				service.$( "$getPresideSetting" ).$args( "email", "ratelimit", 100 ).$results( rateLimit );
				service.$( "autoQueueScheduledSendouts", 345 );

				var resultsList = "";
				for( var i=1; i<=rateLimit; i++ ){
					resultsList = resultsList.listAppend( "emails[#i#]" );
				}
				Evaluate( "service.$( ""getNextQueuedEmail"" ).$results( #resultsList# )" );

				mockEmailService.$( "send", true );
				service.$( "removeFromQueue", 1 );

				service.processQueue();

				expect( mockEmailService.$callLog().send.len() ).toBe( rateLimit );
				expect( service.$callLog().removeFromQueue.len() ).toBe( rateLimit );
				for( var i=1; i<=rateLimit; i++ ){
					expect( mockEmailService.$callLog().send[i] ).toBe( { template=emails[i].template, recipientId=emails[i].recipient } );
					expect( service.$callLog().removeFromQueue[i] ).toBe( [ emails[i].id ] );
				}
			} );

			it( "should stop processing before the rate limit if an empty struct is returned from getNextQueuedEmail()", function(){
				var service   = _getService();
				var rateLimit = 10;
				var emails    = [];

				for( var i=1; i<=3; i++ ) {
					emails.append({
						  id        = CreateUUId()
						, template  = CreateUUId()
						, recipient = CreateUUId()
					});
				}
				emails.append({});

				service.$( "$getPresideSetting" ).$args( "email", "ratelimit", 100 ).$results( rateLimit );
				service.$( "autoQueueScheduledSendouts", 345 );

				var resultsList = "";
				for( var i=1; i<=emails.len(); i++ ){
					resultsList = resultsList.listAppend( "emails[#i#]" );
				}
				Evaluate( "service.$( ""getNextQueuedEmail"" ).$results( #resultsList# )" );

				mockEmailService.$( "send", true );
				service.$( "removeFromQueue", 1 );

				service.processQueue();

				expect( mockEmailService.$callLog().send.len() ).toBe( emails.len()-1 );
				expect( service.$callLog().removeFromQueue.len() ).toBe( emails.len()-1 );
				for( var i=1; i<=emails.len()-1; i++ ){
					expect( mockEmailService.$callLog().send[i] ).toBe( { template=emails[i].template, recipientId=emails[i].recipient } );
					expect( service.$callLog().removeFromQueue[i] ).toBe( [ emails[i].id ] );
				}
			} );

			it( "should manually clear queue query caches because we are bypassing cache due to running in background thread", function(){
				var service   = _getService();
				var rateLimit = 31;
				var emails    = [];

				for( var i=1; i<=40; i++ ) {
					emails.append({
						  id        = CreateUUId()
						, template  = CreateUUId()
						, recipient = CreateUUId()
					});
				}
				emails.append({});

				service.$( "$getPresideSetting" ).$args( "email", "ratelimit", 100 ).$results( rateLimit );
				service.$( "autoQueueScheduledSendouts", 345 );

				var resultsList = "";
				for( var i=1; i<=emails.len(); i++ ){
					resultsList = resultsList.listAppend( "emails[#i#]" );
				}
				Evaluate( "service.$( ""getNextQueuedEmail"" ).$results( #resultsList# )" );

				mockEmailService.$( "send", true );
				service.$( "removeFromQueue", 1 );

				service.processQueue();
				expect( mockPresideObjectService.$callLog().clearRelatedCaches.len() ).toBe( 5 );
				for( var log in mockPresideObjectService.$callLog().clearRelatedCaches ) {
					expect( log ).toBe( [ "email_mass_send_queue" ] );
				}
			} );
		} );

		describe( "autoQueueScheduledSendouts()", function(){
			it( "should fetch any unsent one-time emails and add them to the queue", function(){
				var service = _getService();
				var templates = [ CreateUUId(), CreateUUId(), CreateUUId() ];

				mockEmailTemplateService.$( "listDueOneTimeScheduleTemplates", templates );
				mockEmailTemplateService.$( "listDueRepeatedScheduleTemplates", [] );
				mockEmailTemplateService.$( "updateScheduledSendFields", 1 );
				service.$( "queueSendout", 1 );

				service.autoQueueScheduledSendouts();

				expect( service.$callLog().queueSendout.len() ).toBe( templates.len() );
				for( var i=1; i<=templates.len(); i++ ) {
					expect( service.$callLog().queueSendout[i] ).toBe( [ templates[i] ] );
				}
			} );

			it( "should mark one-time emails as sent, once added to the queue", function(){
				var service = _getService();
				var templates = [ CreateUUId(), CreateUUId(), CreateUUId() ];

				mockEmailTemplateService.$( "listDueOneTimeScheduleTemplates", templates );
				mockEmailTemplateService.$( "listDueRepeatedScheduleTemplates", [] );
				mockEmailTemplateService.$( "updateScheduledSendFields", 1 );
				service.$( "queueSendout", 1 );

				service.autoQueueScheduledSendouts();

				expect( mockEmailTemplateService.$callLog().updateScheduledSendFields.len() ).toBe( templates.len() );
				for( var i=1; i<=templates.len(); i++ ) {
					expect( mockEmailTemplateService.$callLog().updateScheduledSendFields[i] ).toBe( { templateId=templates[i], markAsSent=true } );
				}
			} );

			it( "should fetch any unsent repeated emails and add them to the queue", function(){
				var service = _getService();
				var templates = [ CreateUUId(), CreateUUId(), CreateUUId() ];

				mockEmailTemplateService.$( "listDueOneTimeScheduleTemplates", [] );
				mockEmailTemplateService.$( "listDueRepeatedScheduleTemplates", templates );
				mockEmailTemplateService.$( "updateScheduledSendFields", 1 );
				service.$( "queueSendout", 1 );

				service.autoQueueScheduledSendouts();

				expect( service.$callLog().queueSendout.len() ).toBe( templates.len() );
				for( var i=1; i<=templates.len(); i++ ) {
					expect( service.$callLog().queueSendout[i] ).toBe( [ templates[i] ] );
				}
			} );

			it( "should update schedule for each repeated schedule email, once added to the queue", function(){
				var service = _getService();
				var templates = [ CreateUUId(), CreateUUId(), CreateUUId() ];

				mockEmailTemplateService.$( "listDueOneTimeScheduleTemplates", [] );
				mockEmailTemplateService.$( "listDueRepeatedScheduleTemplates", templates );
				mockEmailTemplateService.$( "updateScheduledSendFields", 1 );
				service.$( "queueSendout", 1 );

				service.autoQueueScheduledSendouts();

				expect( mockEmailTemplateService.$callLog().updateScheduledSendFields.len() ).toBe( templates.len() );
				for( var i=1; i<=templates.len(); i++ ) {
					expect( mockEmailTemplateService.$callLog().updateScheduledSendFields[i] ).toBe( { templateId=templates[i] } );
				}
			} );

			it( "should return the total number of queued emails", function(){
				var service           = _getService();
				var oneTimeTemplates  = [ CreateUUId(), CreateUUId(), CreateUUId() ];
				var repeatedTemplates = [ CreateUUId(), CreateUUId() ];

				mockEmailTemplateService.$( "listDueOneTimeScheduleTemplates", oneTimeTemplates );
				mockEmailTemplateService.$( "listDueRepeatedScheduleTemplates", repeatedTemplates );
				mockEmailTemplateService.$( "updateScheduledSendFields", 1 );
				service.$( "queueSendout" ).$results( 234, 34, 56, 0, 3462 );

				expect( service.autoQueueScheduledSendouts()  ).toBe( 234 + 34 + 56 + 3462 );
			} );
		} );
	}

// PRIVATE HELPERS
	private any function _getService() {
		mockEmailService              = createEmptyMock( "preside.system.services.email.EmailService"                   );
		mockEmailTemplateService      = createEmptyMock( "preside.system.services.email.EmailTemplateService"           );
		mockEmailRecipientTypeService = createEmptyMock( "preside.system.services.email.EmailRecipientTypeService"      );
		mockRulesEngineFilterService  = createEmptyMock( "preside.system.services.rulesEngine.RulesEngineFilterService" );
		mockPresideObjectService      = createEmptyMock( "preside.system.services.presideObjects.PresideObjectService"  );
		mockQueueDao                  = CreateStub();
		mockLogDao                    = CreateStub();
		mockDbAdapter                 = CreateStub();

		var service = createMock( object=new preside.system.services.email.EmailMassSendingService(
			  emailTemplateService      = mockEmailTemplateService
			, emailRecipientTypeService = mockEmailRecipientTypeService
			, emailService              = mockEmailService
			, rulesEngineFilterService  = mockRulesEngineFilterService
		) );

		service.$( "$getPresideObject" ).$args( "email_mass_send_queue" ).$results( mockQueueDao );
		service.$( "$getPresideObject" ).$args( "email_template_send_log" ).$results( mockLogDao );
		service.$( "$getPresideObjectService", mockPresideObjectService );
		service.$( "$isInterrupted", false );
		service.$( "$announceInterception" );
		mockPresideObjectService.$( "getDbAdapterForObject", mockDbAdapter );
		mockPresideObjectService.$( "clearRelatedCaches" );

		mockDbAdapter.$( "getNowFunctionSql", "nowwweee()" );

		return service;
	}

	private struct function _getDuplicateCheckFilter( required string recipientObject, required string templateId ) {
		var filter = { filter="already_queued_check.recipient is null", filterParams={ template={ type="cf_sql_varchar", value=arguments.templateId } } };
		var dummySubQuery = "select stuff from stuffz where stuff = 'stuffz'";

		mockQueueDao.$( "selectData" ).$args(
			  selectFields        = [ "recipient", "template" ]
			, getSqlAndParamsOnly = true
		).$results( { sql=dummySubQuery } );

		filter.extraJoins = [{
			  type              = "left"
			, subQuery          = dummySubQuery
			, subQueryAlias     = "already_queued_check"
			, subQueryColumn    = "recipient"
			, joinToTable       = arguments.recipientObject
			, joinToColumn      = "id"
			, additionalClauses = "template = :template"
		} ];

		return filter;
	}
}