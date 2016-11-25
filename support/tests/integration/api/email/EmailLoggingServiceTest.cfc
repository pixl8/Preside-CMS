component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "createEmailLog()", function(){
			it( "should return the newly created ID of a log record created by the method", function(){
				var service = _getService();
				var dummyId = CreateUUId();
				var args    = {
					  template = "sometemplate"
					, recipient = CreateUUId() & "@test.com"
					, sender    = CreateUUId() & "@test.com"
					, subject   = "Some subject " & CreateUUId()
				};

				mockLogDao.$( "insertData" ).$args( {
					  email_template = args.template
					, recipient      = args.recipient
					, sender         = args.sender
					, subject        = args.subject
				}).$results( dummyId );

				expect( service.createEmailLog( argumentCollection=args ) ).toBe( dummyId );
			} );

			it( "should lookup foreign key field and value from the given email template and send 'args' struct", function(){
				var service   = _getService();
				var dummyId   = CreateUUId();
				var dummyFkId = CreateUUId();
				var args      = {
					  template = "sometemplate"
					, recipient = CreateUUId() & "@test.com"
					, sender    = CreateUUId() & "@test.com"
					, subject   = "Some subject " & CreateUUId()
					, sendArgs  = { test=CreateUUId() }
				};
				var dummyTemplate = { recipient_type="sometype" };

				mockEmailTemplateService.$( "getTemplate" ).$args( args.template ).$results( dummyTemplate );
				mockRecipientTypeService.$( "getRecipientId" ).$args( dummyTemplate.recipient_type, args.sendArgs ).$results( dummyFkId );
				mockRecipientTypeService.$( "getRecipientIdLogPropertyForRecipientType" ).$args( dummyTemplate.recipient_type ).$results( "dummyFk" );



				mockLogDao.$( "insertData" ).$args( {
					  email_template = args.template
					, recipient      = args.recipient
					, sender         = args.sender
					, subject        = args.subject
					, dummyFk        = dummyFkId
				}).$results( dummyId );

				expect( service.createEmailLog( argumentCollection=args ) ).toBe( dummyId );
			} );
		} );
	}

	private any function _getService(){
		mockRecipientTypeService = createEmptyMock( "preside.system.services.email.EmailRecipientTypeService" );
		mockEmailTemplateService = createEmptyMock( "preside.system.services.email.EmailTemplateService" );
		mockLogDao = CreateStub();

		var service = createMock( object=new preside.system.services.email.EmailLoggingService(
			  recipientTypeService = mockRecipientTypeService
			, emailTemplateService = mockEmailTemplateService
		) );

		mockEmailTemplateService.$( "getTemplate", { recipient_type="test" } );
		mockRecipientTypeService.$( "getRecipientId", "" );
		mockRecipientTypeService.$( "getRecipientIdLogPropertyForRecipientType", "" );
		service.$( "$getPresideObject" ).$args( "email_template_send_log" ).$results( mockLogDao );

		return service;
	}
}