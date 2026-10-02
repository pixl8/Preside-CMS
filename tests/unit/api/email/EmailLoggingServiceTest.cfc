component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "createEmailLog()", function(){
			it( "should return the newly created ID of a log record created by the method", function(){
				var service = _getService();
				var dummyId = CreateUUId();
				var args    = {
					  template       = "sometemplate"
					, recipientType  = "blah"
					, recipientId    = CreateUUId()
					, recipient      = CreateUUId() & "@test.com"
					, sender         = CreateUUId() & "@test.com"
					, subject        = "Some subject " & CreateUUId()
					, sendArgs       = { blah=CreateUUId() }
					, layoutOverride = ""
					, customLayout   = ""
				};

				mockLogDao.$( "insertData" ).$args( {
					  email_template  = args.template
					, recipient       = args.recipient
					, sender          = args.sender
					, subject         = args.subject
					, resend_of       = ""
					, send_args       = Serializejson( args.sendArgs )
					, layout_override = ""
					, custom_layout   = ""
				}).$results( dummyId );

				expect( service.createEmailLog( argumentCollection=args ) ).toBe( dummyId );
			} );

			it( "should lookup foreign key field and value from the given recipientType and passed recipient ID", function(){
				var service   = _getService();
				var dummyId   = CreateUUId();
				var dummyFkId = CreateUUId();
				var args      = {
					  template       = "sometemplate"
					, recipientId    = dummyFkId
					, recipientType  = "sometype"
					, recipient      = CreateUUId() & "@test.com"
					, sender         = CreateUUId() & "@test.com"
					, subject        = "Some subject " & CreateUUId()
					, sendArgs       = { test=CreateUUId() }
					, layoutOverride = ""
					, customLayout   = ""
				};

				mockRecipientTypeService.$( "getRecipientIdLogPropertyForRecipientType" ).$args( args.recipientType ).$results( "dummyFk" );

				mockLogDao.$( "insertData" ).$args( {
					  email_template  = args.template
					, recipient       = args.recipient
					, sender          = args.sender
					, subject         = args.subject
					, resend_of       = ""
					, dummyFk         = dummyFkId
					, send_args       = Serializejson( args.sendArgs )
					, layout_override = ""
					, custom_layout   = ""
				}).$results( dummyId );

				expect( service.createEmailLog( argumentCollection=args ) ).toBe( dummyId );
			} );
		} );

		describe( "recordActivity()", function(){
			it( "should insert data into email_template_send_log_activity", function(){
				var service   = _getService();
				var messageId = CreateUUId();
				var activity  = "blah";
				var extraData = { blah=CreateUUId(), test=Now() };


				mockLogActivityDao.$( "insertData", CreateUUId() );
				_setupMockMessageQuery( messageId );

				service.recordActivity(
					  messageId = messageId
					, activity  = activity
					, extraData = extraData
				);

				expect( mockLogActivityDao.$callLog().insertData.len() ).toBe( 1 );
				expect( mockLogActivityDao.$callLog().insertData[ 1 ] ).toBe( [ {
					  message       = messageId
					, activity_type = activity
					, extra_data    = SerializeJson( extraData )
					, user_ip       = cgi.remote_addr
					, user_agent    = cgi.http_user_agent
					, datecreated   = Now()
				} ]);
			} );

			it( "should extract known fields from extra data directly into the data model", function(){
				var service   = _getService();
				var messageId = CreateUUId();
				var activity  = "blah";
				var extraData = { blah=CreateUUId(), test=Now() };
				var expectedData = extraData.copy();

				_setupMockMessageQuery( messageId );

				extraData.link = CreateUUId();
				extraData.code = "304.2"
				extraData.reason = "Test reason: " & CreateUUId();

				mockLogActivityDao.$( "insertData", CreateUUId() );

				service.recordActivity(
					  messageId = messageId
					, activity  = activity
					, extraData = extraData
				);

				expect( mockLogActivityDao.$callLog().insertData.len() ).toBe( 1 );
				expect( mockLogActivityDao.$callLog().insertData[ 1 ] ).toBe( [ {
					  message       = messageId
					, activity_type = activity
					, extra_data    = SerializeJson( expectedData )
					, user_ip       = cgi.remote_addr
					, user_agent    = cgi.http_user_agent
					, link          = extraData.link
					, code          = extraData.code
					, reason        = extraData.reason
					, datecreated   = Now()
				} ]);
			} );

			it( "should annouce an interception point based on the activity name so that extensions can trigger logic on activity", function(){
				var service   = _getService();
				var messageId = CreateUUId();
				var activity  = "whatever";
				var extraData = { blah=CreateUUId(), test=Now() };
				var expectedData = extraData.copy();

				_setupMockMessageQuery( messageId );

				extraData.link = CreateUUId();
				extraData.code = "304.2"
				extraData.reason = "Test reason: " & CreateUUId();

				mockLogActivityDao.$( "insertData", CreateUUId() );

				service.recordActivity(
					  messageId = messageId
					, activity  = activity
					, extraData = extraData
				);

				expect( service.$callLog().$announceInterception.len() ).toBe( 1 );
				expect( service.$callLog().$announceInterception[ 1 ] ).toBe( [ "onEmailWhatever", {
					  message       = messageId
					, activity_type = activity
					, extra_data    = SerializeJson( expectedData )
					, user_ip       = cgi.remote_addr
					, user_agent    = cgi.http_user_agent
					, link          = extraData.link
					, code          = extraData.code
					, reason        = extraData.reason
					, datecreated   = Now()
				} ] );
			} );
		} );

		describe( "markAsSent()", function(){
			it( "should update the log record by setting sent = true + sent_date to now(ish) and record an activity", function(){
				var service    = _getService();
				var logId      = CreateUUID();
				var templateId = CreateUUID();

				mockLogDao.$( "updateData", 1 );
				service.$( "recordActivity" );
				mockEmailTemplateService.$( "templateExists" ).$args( id=templateId ).$results( true );
				mockEmailTemplateService.$( "updateLastSentDate" ).$args( templateId=templateId, lastSentDate=nowish ).$results( 1 );

				service.markAsSent( logId, templateId );

				expect( mockLogDao.$callLog().updateData.len() ).toBe( 1 );
				expect( mockLogDao.$callLog().updateData[ 1 ] ).toBe( {
					  id   = logId
					, data = { sent=true, sent_date=nowish }
				} );

				expect( service.$callLog().recordActivity.len() ).toBe( 1 );
				expect( service.$callLog().recordActivity[ 1 ] ).toBe( {
					  messageId = logId
					, activity  = "send"
				} );
			} );
			it( "should not record an activity when log record not updated", function(){
				var service = _getService();
				var logId   = CreateUUId();

				mockLogDao.$( "updateData", 0 );
				service.$( "recordActivity" );

				service.markAsSent( logId );

				expect( service.$callLog().recordActivity.len() ).toBe( 0 );
			} );
		} );

		describe( "markAsDelivered()", function(){
			it( "should mark the given message as delivered when not already delivered and update the delivery date + ensure not marked as failed or hard bounced", function(){
				var service = _getService();
				var logId   = CreateUUId();

				mockLogDao.$( "updateData", 1 );
				service.$( "recordActivity" );

				service.markAsDelivered( logId );

				expect( mockLogDao.$callLog().updateData.len() ).toBe( 1 );
				expect( mockLogDao.$callLog().updateData[ 1 ] ).toBe( {
					  filter       = "id = :id and ( delivered is null or delivered = :delivered )"
					, filterParams = { id=logId, delivered=false }
					, data         = {
						  delivered         = true
						, delivered_date    = nowish
						, failed            = false
						, failed_date       = ""
						, failed_reason     = ""
						, failed_code       = ""
						, hard_bounced      = false
						, hard_bounced_date = ""
					  }
				} );

				expect( service.$callLog().recordActivity.len() ).toBe( 1 );
				expect( service.$callLog().recordActivity[ 1 ] ).toBe( {
					  messageId = logId
					, activity  = "deliver"
				} );
			} );

			it( "should not update the delivery date when 'softMark' set to true", function(){
				var service = _getService();
				var logId   = CreateUUId();

				mockLogDao.$( "updateData", 1 );
				service.$( "recordActivity" );

				service.markAsDelivered( id=logId, softMark=true );

				expect( mockLogDao.$callLog().updateData.len() ).toBe( 1 );
				expect( mockLogDao.$callLog().updateData[ 1 ] ).toBe( {
					  filter       = "id = :id and ( delivered is null or delivered = :delivered )"
					, filterParams = { id=logId, delivered=false }
					, data         = {
						  delivered         = true
						, hard_bounced      = false
						, hard_bounced_date = ""
						, failed            = false
						, failed_date       = ""
						, failed_reason     = ""
						, failed_code       = ""
					  }
				} );
				expect( service.$callLog().recordActivity.len() ).toBe( 1 );
			} );
		} );

		describe( "markAsFailed()", function(){
			it( "should mark the given message as failed when not already failed and update the failure date", function(){
				var service = _getService();
				var logId   = CreateUUId();
				var reason  = "Recipient does not want to see you right now" & CreateUUId();
				var code    = 610;

				mockLogDao.$( "updateData", 1 );
				service.$( "recordActivity" );

				service.markAsFailed( logId, reason, code );

				expect( mockLogDao.$callLog().updateData.len() ).toBe( 1 );
				expect( mockLogDao.$callLog().updateData[ 1 ] ).toBe( {
					  filter       = "id = :id and ( failed is null or failed = :failed ) and ( delivered is null or delivered = :delivered )"
					, filterParams = { id=logId, failed=false, delivered=false }
					, data         = { failed=true, failed_date=nowish, failed_reason=reason, failed_code=code }
				} );

				expect( service.$callLog().recordActivity.len() ).toBe( 1 );
				expect( service.$callLog().recordActivity[ 1 ] ).toBe( {
					  messageId = logId
					, activity  = "fail"
					, extraData = { reason=reason, code=code }
				} );
			} );
		} );

		describe( "markAsHardBounced()", function(){
			it( "should mark the given message as hard bounced when not already bounced, update the bounced date + set as failed", function(){
				var service = _getService();
				var logId   = CreateUUId();
				var reason  = "Unknown address" & CreateUUId();
				var code    = 550;

				mockLogDao.$( "updateData", 1 );
				service.$( "markAsFailed" );

				service.markAsHardBounced( logId, reason, code );

				expect( mockLogDao.$callLog().updateData.len() ).toBe( 1 );
				expect( mockLogDao.$callLog().updateData[ 1 ] ).toBe( {
					  filter       = "id = :id and ( hard_bounced is null or hard_bounced = :hard_bounced ) and ( opened is null or opened = :opened )"
					, filterParams = { id=logId, hard_bounced=false, opened=false }
					, data         = { hard_bounced=true, hard_bounced_date=nowish }
				} );
				expect( service.$callLog().markAsFailed.len() ).toBe( 1 );
				expect( service.$callLog().markAsFailed[1] ).toBe( {
					  id     = logId
					, reason = reason
					, code   = code
				} );
			} );
		} );

		describe( "markAsOpened()", function(){
			it( "should mark the given message as opened when not already opened, log the activity + mark as delivered", function(){
				var service = _getService();
				var logId   = CreateUUId();

				mockLogDao.$( "updateData", 1 );
				service.$( "markAsDelivered" );
				service.$( "recordActivity" );

				service.markAsOpened( logId );

				expect( mockLogDao.$callLog().updateData.len() ).toBe( 1 );
				expect( mockLogDao.$callLog().updateData[ 1 ] ).toBe( {
					  filter       = "id = :id and ( opened is null or opened = :opened )"
					, filterParams = { id=logId, opened=false }
					, data         = { opened=true, opened_date=nowish, open_count=1 }
				} );
				expect( service.$callLog().markAsDelivered.len() ).toBe( 1 );
				expect( service.$callLog().markAsDelivered[1] ).toBe( [ logId, true ] );
				expect( service.$callLog().recordActivity.len() ).toBe( 1 );
				expect( service.$callLog().recordActivity[1].messageId ?: "" ).toBe( logId );
				expect( service.$callLog().recordActivity[1].activity ?: "" ).toBe( "open" );
				expect( service.$callLog().recordActivity[1].first ?: "" ).toBe( true );
			} );

			it( "should stamp opened_date from the supplied event time", function(){
				var service   = _getService();
				var logId     = CreateUUId();
				var eventDate = DateAdd( "n", -2, nowish );

				mockLogDao.$( "updateData", 1 );
				service.$( "markAsDelivered" );
				service.$( "recordActivity" );

				service.markAsOpened( id=logId, eventDate=eventDate );

				expect( mockLogDao.$callLog().updateData[ 1 ].data.opened_date ).toBe( eventDate );
				expect( service.$callLog().recordActivity[ 1 ].eventDate ).toBe( eventDate );
			} );

			it( "should increment open_count when the message was already opened", function(){
				var service = _getService();
				var logId   = CreateUUId();

				mockLogDao.$( "updateData", 0 );
				service.$( "markAsDelivered" );
				service.$( "recordActivity" );

				service.markAsOpened( logId );

				expect( mockSqlRunner.$callLog().runSql.len() ).toBe( 1 );
				expect( mockSqlRunner.$callLog().runSql[ 1 ].sql ).toBe( "update `psys_email_template_send_log` set `open_count` = `open_count` + 1 where `id` = :id" );
				expect( service.$callLog().recordActivity.len() ).toBe( 1 );
				expect( service.$callLog().recordActivity[ 1 ].activity ).toBe( "open" );
			} );

			it( "should not update opened date, increment open_count or track an open when 'softMark' set to true", function(){
				var service = _getService();
				var logId   = CreateUUId();

				mockLogDao.$( "updateData", 1 );
				service.$( "markAsDelivered" );
				service.$( "recordActivity" );

				service.markAsOpened( id=logId, softMark=true );

				expect( mockLogDao.$callLog().updateData.len() ).toBe( 1 );
				expect( mockLogDao.$callLog().updateData[ 1 ] ).toBe( {
					  filter       = "id = :id and ( opened is null or opened = :opened )"
					, filterParams = { id=logId, opened=false }
					, data         = { opened=true }
				} );
				expect( service.$callLog().markAsDelivered.len() ).toBe( 1 );
				expect( service.$callLog().markAsDelivered[1] ).toBe( [ logId, true ] );
				expect( service.$callLog().recordActivity.len() ).toBe( 0 );
				expect( mockSqlRunner.$callLog().runSql.len() ).toBe( 0 );
			} );

			it( "should not increment open_count when a click soft-marks a message that is already opened", function(){
				var service = _getService();
				var logId   = CreateUUId();

				mockLogDao.$( "updateData", 0 );
				service.$( "markAsDelivered" );
				service.$( "recordActivity" );

				service.markAsOpened( id=logId, softMark=true );

				expect( mockSqlRunner.$callLog().runSql.len() ).toBe( 0 );
				expect( service.$callLog().recordActivity.len() ).toBe( 0 );
			} );
		} );

		describe( "markAsMarkedAsSpam()", function(){
			it( "should mark the given message as marked as spam when not already done so", function(){
				var service = _getService();
				var logId   = CreateUUId();

				mockLogDao.$( "updateData", 1 );
				service.$( "recordActivity" );

				service.markAsMarkedAsSpam( logId );

				expect( mockLogDao.$callLog().updateData.len() ).toBe( 1 );
				expect( mockLogDao.$callLog().updateData[ 1 ] ).toBe( {
					  filter       = "id = :id and ( marked_as_spam is null or marked_as_spam = :marked_as_spam )"
					, filterParams = { id=logId, marked_as_spam=false }
					, data         = { marked_as_spam=true, marked_as_spam_date=nowish }
				} );

				expect( service.$callLog().recordActivity.len() ).toBe( 1 );
				expect( service.$callLog().recordActivity[ 1 ] ).toBe( {
					  messageId = logId
					, activity  = "markasspam"
				} );
			} );
			it( "should not record an activity when log record not updated", function(){
				var service = _getService();
				var logId   = CreateUUId();

				mockLogDao.$( "updateData", 0 );
				service.$( "recordActivity" );

				service.markAsMarkedAsSpam( logId );

				expect( service.$callLog().recordActivity.len() ).toBe( 0 );
			} );
		} );

		describe( "markAsUnsubscribed()", function(){
			it( "should mark the given message as unsubscribed when not already done so", function(){
				var service = _getService();
				var logId   = CreateUUId();

				mockLogDao.$( "updateData", 1 );
				service.$( "recordActivity" );

				service.markAsUnsubscribed( logId );

				expect( mockLogDao.$callLog().updateData.len() ).toBe( 1 );
				expect( mockLogDao.$callLog().updateData[ 1 ] ).toBe( {
					  filter       = "id = :id and ( unsubscribed is null or unsubscribed = :unsubscribed )"
					, filterParams = { id=logId, unsubscribed=false }
					, data         = { unsubscribed=true, unsubscribed_date=nowish }
				} );

				expect( service.$callLog().recordActivity.len() ).toBe( 1 );
				expect( service.$callLog().recordActivity[ 1 ] ).toBe( {
					  messageId = logId
					, activity  = "unsubscribe"
				} );
			} );
			it( "should not record an activity when log record not updated", function(){
				var service = _getService();
				var logId   = CreateUUId();

				mockLogDao.$( "updateData", 0 );
				service.$( "recordActivity" );

				service.markAsUnsubscribed( logId );

				expect( service.$callLog().recordActivity.len() ).toBe( 0 );
			} );
		} );

		describe( "recordClick()", function(){
			it( "should increment click count on email log record", function(){
				var service = _getService();
				var logId   = CreateUUId();
				var link    = CreateUUId();
				var mockLog = QueryNew( 'id,click_count', 'varchar,varchar', [[ logId, "" ]] );

				service.$( "markAsOpened" );
				service.$( "recordActivity" );
				mockLogDao.$( "selectData" ).$args( id=logId ).$results( mockLog );
				mockLogDao.$( "updateData", 1 );

				service.recordClick( id=logId, link=link );

				expect( mockLogDao.$callLog().updateData.len() ).toBe( 1 );
				debug( mockLogDao.$callLog().updateData[ 1 ]  );
				expect( mockLogDao.$callLog().updateData[ 1 ] ).toBe( { filter={ id=logId, click_count=0 }, data={ click_count=1, clicked=true } } );

			} );

			it( "should record activity and ensure mail marked as opened", function(){
				var service = _getService();
				var logId   = CreateUUId();
				var link    = CreateUUId();
				var mockLog = QueryNew( 'id,click_count', 'varchar,varchar', [[ logId, 23 ]] );

				service.$( "markAsOpened" );
				service.$( "recordActivity" );
				mockLogDao.$( "selectData" ).$args( id=logId ).$results( mockLog );
				mockLogDao.$( "updateData", 0 );

				mockSqlRunner.$( "runSql", { recordCount=1 } );

				service.recordClick( id=logId, link=link );

				expect( mockLogDao.$callLog().updateData.len() ).toBe( 1 );
				expect( mockSqlRunner.$callLog().runSql.len() ).toBe( 1 );
				expect( mockSqlRunner.$callLog().runSql[ 1 ].sql ).toBe( "update `psys_email_template_send_log` set `click_count` = `click_count` + 1 where `id` = :id" );
				expect( service.$callLog().markAsOpened.len() ).toBe( 1 );
				expect( service.$callLog().markAsOpened[1] ).toBe( { id=logId, softMark=true, userAgent=cgi.http_user_agent, ipAddress=cgi.remote_addr } );
				expect( service.$callLog().recordActivity.len() ).toBe( 1 );
				expect( service.$callLog().recordActivity[1].messageId ?: "" ).toBe( logId );
				expect( service.$callLog().recordActivity[1].activity ?: "" ).toBe( "click" );
				expect( service.$callLog().recordActivity[1].extraData ?: "" ).toBe( { link=link, link_title="", link_body="" } );

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

			it( "should append an off-screen honeypot link when the email tracking bot detection feature is enabled", function() {
				var service = _getService();
				var messageId = CreateUUId();
				var trackingUrl = CreateUUId();
				var honeyPotUrl = CreateUUId();
				var htmlMessage = CreateUUId();
				var htmlMessageWithPixel = htmlMessage & "<img src=""#trackingUrl#"" width=""1"" height=""1"" style=""width:1px;height:1px"" /><a href=""#honeyPotUrl#"" style=""display:inline-block;overflow:hidden;width:1px;height:1px;font-size:1px;line-height:1px;color:transparent;"">Preferences</a>";
				var mockRc = CreateStub();

				service.$( "$getRequestContext", mockRc );
				service.$( "$isFeatureEnabled" ).$args( "emailTrackingBotDetection" ).$results( true );

				mockRc.$( "buildLink" ).$args( linkto="email.tracking.open", querystring="mid=" & messageId ).$results( trackingUrl );
				mockRc.$( "buildLink" ).$args( linkto="email.tracking.honeypot", querystring="mid=" & messageId ).$results( honeyPotUrl );

				expect( service.insertTrackingPixel(
					  messageId   = messageId
					, messageHtml = htmlMessage
				) ).toBe( htmlMessageWithPixel );
			} );
		} );

		describe( "insertClickTrackingLinks", function(){
			it( "should replace all href's in html email content with a tracking link", function(){
				var service = _getService();
				var messageId = CreateUUId();
				var trackingUrl = CreateUUId();
				var links       = [ "https://#CreateUUId()#.com", "http://#CreateUUId()#.com", "http://#CreateUUId()#.com", "https://#CreateUUId()#.com" ];
				var html        = "<!DOCTYPE html>
<html>
<head>
	<title>My email</title>
</head>
<body>
<p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
quis nostrud exercitation <a href=""#links[1]#"">ullamco</a> laboris nisi ut aliquip ex ea commodo
consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non
proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>
<p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
cillum dolore <a href=""#links[2]#"">eu</a> fugiat nulla pariatur. Excepteur sint occaecat cupidatat non
proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>
<p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
quis nostrud exercitation <a href=""#links[3]#"">ullamco laboris</a> nisi ut aliquip ex ea commodo
consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
<a href=""#links[4]#"">cillum dolore</a> eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non
proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>
</body>
</html>";
				var htmlMessageWithClickTrackingLinks = '<!doctype html>
<html>
 <head>
  <title>My email</title>
 </head>
 <body>
  <p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation <a href="#trackingUrl##ToBase64( links[ 1 ] )#">ullamco</a> laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>
  <p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore <a href="#trackingUrl##ToBase64( links[ 2 ] )#">eu</a> fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>
  <p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation <a href="#trackingUrl##ToBase64( links[ 3 ] )#">ullamco laboris</a> nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse <a href="#trackingUrl##ToBase64( links[ 4 ] )#">cillum dolore</a> eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>
 </body>
</html>';

				var mockRc = CreateStub();
				service.$( "$getRequestContext", mockRc );
				mockRc.$( "buildLink" ).$args( linkto="email.tracking.click", querystring="mid=#messageId#&link=" ).$results( trackingUrl );
				mockRc.$( "buildLink" ).$args( linkto="email.tracking.honeypot" ).$results( "https://example.com/e/t/h/" );

				expect( service.insertClickTrackingLinks(
					  messageId   = messageId
					, messageHtml = html
				).reReplace( "\s+", " ", "all" ) ).toBe( htmlMessageWithClickTrackingLinks.reReplace( "\s+", " ", "all" ) );
			} );

			it( "should leave a path-mounted honeypot link unrewritten", function(){
				var service      = _getService();
				var messageId    = CreateUUId();
				var trackingUrl  = "https://example.com/subsite/e/t/c/?mid=#messageId#&link=";
				var honeyPotUrl  = "https://example.com/subsite/e/t/h/?mid=#messageId#";
				var normalLink   = "https://example.com/news";
				var html         = '<html><body><a href="#honeyPotUrl#">trap</a><a href="#normalLink#">news</a></body></html>';
				var mockRc       = CreateStub();

				service.$( "$getRequestContext", mockRc );
				mockRc.$( "buildLink" ).$args( linkto="email.tracking.click", querystring="mid=#messageId#&link=" ).$results( trackingUrl );
				mockRc.$( "buildLink" ).$args( linkto="email.tracking.honeypot" ).$results( "https://example.com/subsite/e/t/h/" );

				var rewritten = service.insertClickTrackingLinks(
					  messageId   = messageId
					, messageHtml = html
				);

				expect( rewritten ).toInclude( honeyPotUrl );
				expect( rewritten ).toInclude( "mid=#messageId#&amp;link=#ToBase64( normalLink )#" );
				expect( rewritten ).notToInclude( ToBase64( honeyPotUrl ) );
			} );
		} );

		describe( "recomputeOpenAndClickCounts()", function(){
			it( "should replace open and click counts from activity rows", function(){
				var service    = _getService();
				var templateId = CreateUUId();

				mockLogActivityDao.$( "getTableName", "psys_email_template_send_log_activity" );

				service.recomputeOpenAndClickCounts( templateId=templateId );

				expect( mockSqlRunner.$callLog().runSql.len() ).toBe( 2 );
				expect( mockSqlRunner.$callLog().runSql[ 1 ].sql ).toInclude( "`open_count`" );
				expect( mockSqlRunner.$callLog().runSql[ 1 ].sql ).toInclude( "coalesce" );
				expect( mockSqlRunner.$callLog().runSql[ 1 ].params[ 1 ].value ).toBe( "open" );
				expect( mockSqlRunner.$callLog().runSql[ 1 ].params[ 2 ].value ).toBe( templateId );
				expect( mockSqlRunner.$callLog().runSql[ 2 ].sql ).toInclude( "`click_count`" );
				expect( mockSqlRunner.$callLog().runSql[ 2 ].params[ 1 ].value ).toBe( "click" );
			} );
		} );

		describe( "processOpenEventWithBotDetection()", function(){
			it( "should record a bot_open activity when the event is classified as a bot", function(){
				var service   = _getService();
				var logId     = CreateUUId();
				var eventDate = DateAdd( "n", -2, Now() );

				mockBotDetectionService.$( "isBot", true );
				service.$( "recordActivity" );

				service.processOpenEventWithBotDetection(
					  messageId = logId
					, userAgent = "scanner"
					, ipAddress = "1.2.3.4"
					, eventDate = eventDate
				);

				expect( service.$callLog().recordActivity.len() ).toBe( 1 );
				expect( service.$callLog().recordActivity[ 1 ].activity ).toBe( "bot_open" );
				expect( service.$callLog().recordActivity[ 1 ].messageId ).toBe( logId );
				expect( service.$callLog().recordActivity[ 1 ].eventDate ).toBe( eventDate );
			} );
		} );

		describe( "processClickEventWithBotDetection()", function(){
			it( "should record a bot_click activity when the event is classified as a bot", function(){
				var service   = _getService();
				var logId     = CreateUUId();
				var link      = "https://example.com/news";
				var eventDate = DateAdd( "n", -2, Now() );

				mockBotDetectionService.$( "isBot", true );
				service.$( "recordActivity" );

				service.processClickEventWithBotDetection(
					  messageId = logId
					, link      = link
					, eventDate = eventDate
					, userAgent = "scanner"
					, ipAddress = "1.2.3.4"
				);

				expect( service.$callLog().recordActivity.len() ).toBe( 1 );
				expect( service.$callLog().recordActivity[ 1 ].activity ).toBe( "bot_click" );
				expect( service.$callLog().recordActivity[ 1 ].extraData ).toBe( { link=link, link_title="", link_body="" } );
				expect( service.$callLog().recordActivity[ 1 ].eventDate ).toBe( eventDate );
			} );
		} );

		describe( "insertClickTrackingLinks() honeypot markup", function(){
			it( "should leave the off-screen honeypot link unrewritten", function(){
				var service     = _getService();
				var messageId   = CreateUUId();
				var trackingUrl = "https://example.com/e/t/o/?mid=#messageId#";
				var honeyPotUrl = "https://example.com/e/t/h/?mid=#messageId#";
				var html        = "<html><body><p>Hello</p></body></html>";
				var mockRc      = CreateStub();

				service.$( "$getRequestContext", mockRc );
				service.$( "$isFeatureEnabled" ).$args( "emailTrackingBotDetection" ).$results( true );
				mockRc.$( "buildLink" ).$args( linkto="email.tracking.open", querystring="mid=" & messageId ).$results( trackingUrl );
				mockRc.$( "buildLink" ).$args( linkto="email.tracking.honeypot", querystring="mid=" & messageId ).$results( honeyPotUrl );
				mockRc.$( "buildLink" ).$args( linkto="email.tracking.click", querystring="mid=#messageId#&link=" ).$results( "https://example.com/e/t/c/?mid=#messageId#&link=" );
				mockRc.$( "buildLink" ).$args( linkto="email.tracking.honeypot" ).$results( "https://example.com/e/t/h/" );

				var withPixel = service.insertTrackingPixel( messageId=messageId, messageHtml=html );
				var rewritten = service.insertClickTrackingLinks( messageId=messageId, messageHtml=withPixel );

				expect( withPixel ).toInclude( honeyPotUrl );
				expect( rewritten ).toInclude( honeyPotUrl );
				expect( rewritten ).notToInclude( ToBase64( honeyPotUrl ) );
			} );
		} );

		describe( "applyTrackingClassification()", function(){
			it( "should move a tentative click that scores as a bot onto bot_click", function(){
				var service    = _getService();
				var activityId = CreateUUId();
				var messageId  = CreateUUId();
				var eventDate  = DateAdd( "n", -5, Now() );

				mockLogActivityDao.$( "updateData", 1 );
				service.$( "_processEventForStatsTables" );

				service.applyTrackingClassification(
					  activity = {
						  id             = activityId
						, message        = messageId
						, activityType   = "click"
						, classification = "tentative"
						, userAgent      = "SameAgent"
						, ipAddress      = "198.51.100.10"
						, eventDate      = eventDate
						, link           = "https://example.com/news"
						, linkTitle      = ""
						, linkBody       = ""
					}
					, score = { isBot=true, score=50, signals=[ "honeypot_user_agent" ] }
				);

				expect( mockLogActivityDao.$callLog().updateData[ 1 ].data.activity_type ).toBe( "bot_click" );
				expect( mockLogActivityDao.$callLog().updateData[ 1 ].data.classification ).toBe( "bot" );
				expect( service.$callLog()._processEventForStatsTables[ 1 ].activity ).toBe( "bot_click" );
			} );
		} );

		describe( "classifyMessageTracking()", function(){
			it( "should reclassify an earlier tentative click when a honeypot hit shares its user agent", function(){
				var service   = _getService();
				var messageId = CreateUUId();
				var clickId   = CreateUUId();
				var clickDate = DateAdd( "n", -2, Now() );
				var rows      = QueryNew(
					  "id,message,activity_type,user_agent,user_ip,datecreated,link,link_title,link_body,classification,extra_data"
					, "varchar,varchar,varchar,varchar,varchar,timestamp,varchar,varchar,varchar,varchar,varchar"
					, [ [
						  clickId
						, messageId
						, "click"
						, "SameAgent"
						, "198.51.100.10"
						, clickDate
						, "https://example.com/news"
						, ""
						, ""
						, "tentative"
						, "{""accept_language"":""en""}"
					] ]
				);

				mockLogActivityDao.$( "selectData", rows );
				mockLogDao.$( "selectData", QueryNew( "sent_date", "timestamp", [ [ DateAdd( "h", -1, clickDate ) ] ] ) );
				mockLogActivityDao.$( "updateData", 1 );
				mockBotDetectionService.$( "getBotDetectionSettings", {
					  sweepDelaySeconds       = 90
					, reclassifyWindowSeconds = 1800
					, eventCountThreshold     = 6
				} );
				mockBotDetectionService.$( "scoreTrackingEvent", { isBot=true, score=50, signals=[ "honeypot_user_agent" ] } );
				service.$( "_processEventForStatsTables" );

				service.classifyMessageTracking( messageId, true );

				expect( mockLogActivityDao.$callLog().updateData[ 1 ].data.activity_type ).toBe( "bot_click" );
				expect( service.$callLog()._processEventForStatsTables[ 1 ].activity ).toBe( "bot_click" );
			} );
		} );
	}

	private any function _getService(){
		mockRecipientTypeService = createEmptyMock( "preside.system.services.email.EmailRecipientTypeService" );
		mockEmailTemplateService = createEmptyMock( "preside.system.services.email.EmailTemplateService" );
		mockEmailStatsService    = createEmptyMock( "preside.system.services.email.EmailStatsService" );
		mockBotDetectionService  = createEmptyMock( "preside.system.services.email.EmailBotDetectionService" );
		mockPresideObjectService = createEmptyMock( "preside.system.services.presideObjects.PresideObjectService" );
		mockLogDao               = CreateStub();
		mockLogActivityDao       = CreateStub();
		mockHelpers              = CreateStub();
		mockSqlRunner            = CreateStub();

		var service = createMock( object=new preside.system.services.email.EmailLoggingService(
			  recipientTypeService     = mockRecipientTypeService
			, emailTemplateService     = mockEmailTemplateService
			, emailStatsService        = mockEmailStatsService
			, emailBotDetectionService = mockBotDetectionService
			, sqlRunner                = mockSqlRunner
		) );

		mockRecipientTypeService.$( "getRecipientId", "" );
		mockRecipientTypeService.$( "getRecipientIdLogPropertyForRecipientType", "" );
		mockRecipientTypeService.$( "getRecipientAdditionalLogProperties", {} );
		service.$( "$getPresideObjectService", mockPresideObjectService );
		service.$( "$getPresideObject" ).$args( "email_template_send_log" ).$results( mockLogDao );
		service.$( "$getPresideObject" ).$args( "email_template_send_log_activity" ).$results( mockLogActivityDao );
		service.$( "$isFeatureEnabled" ).$args( "emailLinkShortener" ).$results( false );
		service.$( "$isFeatureEnabled" ).$args( "emailStyleInlinerAscii" ).$results( false );
		service.$( "$isFeatureEnabled" ).$args( "emailTrackingBotDetection" ).$results( false );
		service.$( "$announceInterception" );

		nowish  = Now();
		service.$( "_getNow", nowish );

		service.$property( propertyName="$helpers", mock=mockHelpers );
		mockHelpers.$( method="isEmptyString", callback=function( val ){
			return !Len( Trim( arguments.val ) ) ;
		} );

		mockSqlRunner.$( "runSql" );
		mockLogDao.$( "getDsn", "dummyvalue" );
		mockLogDao.$( "getTableName", "psys_email_template_send_log" );
		mockLogDao.$( "getDbAdapter", super._getDbAdapter() );

		return service;
	}

	private function _setupMockMessageQuery( messageId, result=QueryNew( "email_template" ) ) {
		mockPresideObjectService.$( "selectData" ).$args(
				  objectName   = "email_template_send_log"
				, selectFields = [ "email_template" ]
				, forceJoins   = "inner"
				, filter       = {
					  id                                        = arguments.messageId
					, "email_template.stats_collection_enabled" = true
				  }
		).$results( arguments.result );
	}
}