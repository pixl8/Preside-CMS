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
					, sending_limit         = "none"
					, sending_limit_unit    = ""
					, sending_limit_measure = ""
				};

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
						, extraFilters = [ preparedFilter ]
						, filterParams = { template = { type="cf_sql_varchar", value=templateId } }
					}
				).$results( queuedCount )

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
					, sending_limit         = "none"
					, sending_limit_unit    = ""
					, sending_limit_measure = ""
				};

				mockEmailTemplateService.$( "getTemplate" ).$args( templateId ).$results( template );
				mockEmailRecipientTypeService.$( "getFilterObjectForRecipientType" ).$args( recipientType ).$results( recipientObject );

				try {
					service.queueSendout( templateId );
				} catch( "preside.mass.email.invalid.recipient.type" e ) {
					expect( e.message ).toBe( "The template, [#templateId#], cannot be queued for mass sending because it's recipient type, [#recipientType#], does not cite a filter object from which to draw the recipients" );
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
					, sending_limit         = "none"
					, sending_limit_unit    = ""
					, sending_limit_measure = ""
				};

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
						, extraFilters = []
						, filterParams = { template = { type="cf_sql_varchar", value=templateId } }
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

				service.$( "getFiltersForSendLimits" ).$args(
					  recipientType = recipientType
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
						, extraFilters = limitFilters
						, filterParams = { template = { type="cf_sql_varchar", value=templateId } }
					}
				).$results( queuedCount )

				expect( service.queueSendout( templateId ) ).toBe( queuedCount );
			} );
		} );
	}

// PRIVATE HELPERS
	private any function _getService() {
		mockEmailTemplateService      = createEmptyMock( "preside.system.services.email.EmailTemplateService"           );
		mockEmailRecipientTypeService = createEmptyMock( "preside.system.services.email.EmailRecipientTypeService"      );
		mockRulesEngineFilterService  = createEmptyMock( "preside.system.services.rulesEngine.RulesEngineFilterService" );
		mockPresideObjectService      = createEmptyMock( "preside.system.services.presideObjects.PresideObjectService"  );
		mockQueueDao                  = CreateStub();
		mockDbAdapter                 = CreateStub();

		var service = createMock( object=new preside.system.services.email.EmailMassSendingService(
			  emailTemplateService      = mockEmailTemplateService
			, emailRecipientTypeService = mockEmailRecipientTypeService
			, rulesEngineFilterService  = mockRulesEngineFilterService
		) );


		service.$( "$getPresideObject" ).$args( "email_mass_send_queue" ).$results( mockQueueDao );
		service.$( "$getPresideObjectService", mockPresideObjectService );
		mockPresideObjectService.$( "getDbAdapterForObject", mockDbAdapter );

		mockDbAdapter.$( "getNowFunctionSql", "nowwweee()" );

		return service;
	}
}