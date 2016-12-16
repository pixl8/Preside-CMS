component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "createEmailLog()", function(){
			it( "should return the newly created ID of a log record created by the method", function(){
				var service = _getService();
				var dummyId = CreateUUId();
				var args    = {
					  template      = "sometemplate"
					, recipientType = "blah"
					, recipientId   = CreateUUId()
					, recipient     = CreateUUId() & "@test.com"
					, sender        = CreateUUId() & "@test.com"
					, subject       = "Some subject " & CreateUUId()
					, sendArgs      = { blah=CreateUUId() }
				};

				mockLogDao.$( "insertData" ).$args( {
					  email_template = args.template
					, recipient      = args.recipient
					, sender         = args.sender
					, subject        = args.subject
					, send_args      = Serializejson( args.sendArgs )
				}).$results( dummyId );

				expect( service.createEmailLog( argumentCollection=args ) ).toBe( dummyId );
			} );

			it( "should lookup foreign key field and value from the given recipientType and passed recipient ID", function(){
				var service   = _getService();
				var dummyId   = CreateUUId();
				var dummyFkId = CreateUUId();
				var args      = {
					  template      = "sometemplate"
					, recipientId   = dummyFkId
					, recipientType = "sometype"
					, recipient     = CreateUUId() & "@test.com"
					, sender        = CreateUUId() & "@test.com"
					, subject       = "Some subject " & CreateUUId()
					, sendArgs      = { test=CreateUUId() }
				};

				mockRecipientTypeService.$( "getRecipientIdLogPropertyForRecipientType" ).$args( args.recipientType ).$results( "dummyFk" );

				mockLogDao.$( "insertData" ).$args( {
					  email_template = args.template
					, recipient      = args.recipient
					, sender         = args.sender
					, subject        = args.subject
					, dummyFk        = dummyFkId
					, send_args      = Serializejson( args.sendArgs )
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

		describe( "markAsDelivered()", function(){
			it( "should mark the given message as delivered when not already delivered and update the delivery date", function(){
				var service = _getService();
				var logId   = CreateUUId();

				mockLogDao.$( "updateData" );

				service.markAsDelivered( logId );

				expect( mockLogDao.$callLog().updateData.len() ).toBe( 1 );
				expect( mockLogDao.$callLog().updateData[ 1 ] ).toBe( {
					  filter       = "id = :id and ( delivered is null or delivered = :delivered )"
					, filterParams = { id=logId, delivered=false }
					, data         = { delivered=true, delivered_date=nowish }
				} );
			} );
		} );

		describe( "markAsOpened()", function(){
			it( "should mark the given message as opened when not already opened + mark as delivered", function(){
				var service = _getService();
				var logId   = CreateUUId();

				mockLogDao.$( "updateData" );
				service.$( "markAsDelivered" );

				service.markAsOpened( logId );

				expect( mockLogDao.$callLog().updateData.len() ).toBe( 1 );
				expect( mockLogDao.$callLog().updateData[ 1 ] ).toBe( {
					  filter       = "id = :id and ( opened is null or opened = :opened )"
					, filterParams = { id=logId, opened=false }
					, data         = { opened=true, opened_date=nowish }
				} );
				expect( service.$callLog().markAsDelivered.len() ).toBe( 1 );
				expect( service.$callLog().markAsDelivered[1] ).toBe( [ logId ] );
			} );
		} );

		describe( "insertTrackingPixel", function(){
			it( "should generate a tracking URL based on the message ID and insert 1x1 tracking image in html email content (returning the new content)", function(){
				var service = _getService();
				var messageId = CreateUUId();
				var trackingUrl = CreateUUId();
				var htmlMessage = "<!DOCTYPE html><html><head><title>Some email</title></head>
<body>
email content
</body>
</html>";
				var htmlMessageWithPixel = "<!DOCTYPE html><html><head><title>Some email</title></head>
<body>
email content
<img src=""#trackingUrl#"" width=""1"" height=""1"" style=""width:1px;height:1px"" /></body>
</html>";

				var mockRc = CreateStub();
				service.$( "$getRequestContext", mockRc );
				mockRc.$( "buildLink" ).$args( linkto="email.tracking.open", querystring="mid=" & messageId ).$results( trackingUrl );

				expect( service.insertTrackingPixel(
					  messageId   = messageId
					, messageHtml = htmlMessage
				) ).toBe( htmlMessageWithPixel );
			} );

			it( "should append the tracking pixel to the message, when no html body tags found", function(){
				var service = _getService();
				var messageId = CreateUUId();
				var trackingUrl = CreateUUId();
				var htmlMessage = CreateUUId();
				var htmlMessageWithPixel = htmlMessage & "<img src=""#trackingUrl#"" width=""1"" height=""1"" style=""width:1px;height:1px"" />";
				var mockRc = CreateStub();

				service.$( "$getRequestContext", mockRc );
				mockRc.$( "buildLink" ).$args( linkto="email.tracking.open", querystring="mid=" & messageId ).$results( trackingUrl );

				expect( service.insertTrackingPixel(
					  messageId   = messageId
					, messageHtml = htmlMessage
				) ).toBe( htmlMessageWithPixel );

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