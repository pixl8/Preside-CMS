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
				};

				mockEmailTemplateService.$( "getTemplate" ).$args( templateId ).$results( template );
				mockEmailRecipientTypeService.$( "getFilterObjectForRecipientType" ).$args( recipientType ).$results( recipientObject );
				mockRulesEngineFilterService.$( "getExpressionArrayForSavedFilter" ).$args( filterId ).$results( expressionArray );
				mockRulesEngineFilterService.$( "prepareFilter" ).$args( objectName=recipientObject, expressionArray=expressionArray ).$results( preparedFilter );

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