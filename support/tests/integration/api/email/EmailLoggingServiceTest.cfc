component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "createEmailLog()", function(){
			it( "should return the newly created ID of a log record created by the method", function(){
				var service = _getService();
				var dummyId = CreateUUId();
				var args    = {
					  template      = "sometemplate"
					, recipientType = "blah"
					, recipient     = CreateUUId() & "@test.com"
					, sender        = CreateUUId() & "@test.com"
					, subject       = "Some subject " & CreateUUId()
				};

				mockLogDao.$( "insertData" ).$args( {
					  email_template = args.template
					, recipient      = args.recipient
					, sender         = args.sender
					, subject        = args.subject
				}).$results( dummyId );

				expect( service.createEmailLog( argumentCollection=args ) ).toBe( dummyId );
			} );

			it( "should lookup foreign key field and value from the given recipientType and send 'args' struct", function(){
				var service   = _getService();
				var dummyId   = CreateUUId();
				var dummyFkId = CreateUUId();
				var args      = {
					  template      = "sometemplate"
					, recipientType = "sometype"
					, recipient     = CreateUUId() & "@test.com"
					, sender        = CreateUUId() & "@test.com"
					, subject       = "Some subject " & CreateUUId()
					, sendArgs      = { test=CreateUUId() }
				};

				mockRecipientTypeService.$( "getRecipientId" ).$args( args.recipientType, args.sendArgs ).$results( dummyFkId );
				mockRecipientTypeService.$( "getRecipientIdLogPropertyForRecipientType" ).$args( args.recipientType ).$results( "dummyFk" );

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

		describe( "markAsSent()", function(){
			it( "should update the log record by setting sent = true + sent_date to now(ish)", function(){
				var service = _getService();
				var logId   = CreateUUId();

				mockLogDao.$( "updateData" );

				service.markAsSent( logId );

				expect( mockLogDao.$callLog().updateData.len() ).toBe( 1 );
				expect( mockLogDao.$callLog().updateData[ 1 ] ).toBe( {
					  id   = logId
					, data = { sent=true, sent_date=nowish }
				} );
			} );
		} );
	}

	private any function _getService(){
		mockRecipientTypeService = createEmptyMock( "preside.system.services.email.EmailRecipientTypeService" );
		mockLogDao = CreateStub();

		var service = createMock( object=new preside.system.services.email.EmailLoggingService(
			recipientTypeService = mockRecipientTypeService
		) );

		mockRecipientTypeService.$( "getRecipientId", "" );
		mockRecipientTypeService.$( "getRecipientIdLogPropertyForRecipientType", "" );
		service.$( "$getPresideObject" ).$args( "email_template_send_log" ).$results( mockLogDao );

		nowish  = Now();
		service.$( "_getNow", nowish );

		return service;
	}
}