component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "listTemplates()", function(){
			it( "should return an array of tempaltes that have been scanned from convention based folder under handlers", function(){
				var emailService      = _getEmailService();
				var expectedTemplates = [ "notification", "resetAdminPassword", "resetWebsitePassword" ];

				expect( emailService.listTemplates() ).toBe( expectedTemplates );
			} );
		} );

		describe( "send()", function(){
			it( "should run template handler to mixin variables that are then forwarded to the email provider send call", function(){
				var emailService      = _getEmailService();
				var testToAddresses   = [ "dominic.watson@test.com", "another.test.com" ];
				var testArgs          = { some="test", data=true, template="notification" };
				var testHandlerResult = { from="someone@test.com", cc="someoneelse@test.com", htmlBody="test body", subject="This is a subject" };
				var expectedSendArgs  = {
					  from                  = ""
					, recipientId           = ""
					, subject               = ""
					, to                    = testToAddresses
					, cc                    = []
					, bcc                   = []
					, replyto               = []
					, failto                = []
					, htmlBody              = ""
					, textBody              = ""
					, params                = {}
					, template              = "notification"
					, resendOf              = ""
					, returnLogId           = false
					, overwriteTemplateArgs = false
					, args                  = testArgs
					, isTest                = false
				};

				expectedSendArgs.append( testHandlerResult );

				mockColdBox.$( "runEvent" ).$results( testHandlerResult );

				emailService.send(
					  template = "notification"
					, to       = testToAddresses
					, args     = testArgs
				);

				expect( mockServiceProviderService.$callLog().sendWithProvider.len() ).toBe( 1 );
				expect( mockServiceProviderService.$callLog().sendWithProvider[1] ).toBe( {
					  provider = defaultProvider
					, sendArgs = expectedSendArgs
					, logSend  = true
				} );
			} );

			it( "should use new (as of 10.8.0) email template service to prepare message data when the template is registered with the new service", function(){
				var emailService        = _getEmailService();
				var testArgs            = { some="test", data=true, template="notification" };
				var recipientId         = CreateUUId();
				var testPreparedMessage = { from="someone@test.com", to="to@test.com", cc="someoneelse@test.com", htmlBody="test body", subject="This is a subject", textBody="text only body" };
				var expectedSendArgs  = {
					  from                  = ""
					, subject               = ""
					, to                    = ""
					, cc                    = []
					, bcc                   = []
					, replyto               = []
					, failto                = []
					, htmlBody              = ""
					, textBody              = ""
					, params                = {}
					, template              = "notification"
					, resendOf              = ""
					, returnLogId           = false
					, overwriteTemplateArgs = false
					, recipientId           = recipientId
					, args                  = testArgs
					, isTest                = false
				};
				expectedPrepArgs = {
					  template              = "notification"
					, recipientId           = recipientId
					, args                  = testArgs
					, to                    = []
					, from                  = ""
					, subject               = ""
					, cc                    = []
					, bcc                   = []
					, replyto               = []
					, failto                = []
					, htmlBody              = ""
					, textBody              = ""
					, params                = {}
					, resendOf              = ""
					, returnLogId           = false
					, overwriteTemplateArgs = false
					, isTest                = false
				};

				expectedSendArgs.append( testPreparedMessage );

				mockEmailTemplateService.$( "templateExists" ).$args( "notification" ).$results( true );
				mockEmailTemplateService.$( "prepareMessage" ).$args( argumentCollection=expectedPrepArgs ).$results( testPreparedMessage );

				emailService.send(
					  template    = "notification"
					, recipientId = recipientId
					, args        = testArgs
				);

				expect( mockServiceProviderService.$callLog().sendWithProvider.len() ).toBe( 1 );
				expect( mockServiceProviderService.$callLog().sendWithProvider[1] ).toBe( {
					  provider = defaultProvider
					, sendArgs = expectedSendArgs
					, logSend  = true
				} );
			} );

			it( "should use default from email setting when no from address is returned from the template handler", function(){
				var emailService      = _getEmailService();
				var testToAddresses   = [ "dominic.watson@test.com", "another@test.com" ];
				var testArgs          = { some="test", data=true, template="notification" };
				var testHandlerResult = { cc="someoneelse@test.com", htmlBody="test body", subject="This is a subject" };
				var testDefaultFrom   = "default@test.com";
				var expectedSendArgs  = {
					  from                  = testDefaultFrom
					, recipientId           = ""
					, subject               = ""
					, to                    = testToAddresses
					, cc                    = []
					, bcc                   = []
					, replyto               = []
					, failto                = []
					, htmlBody              = ""
					, textBody              = ""
					, params                = {}
					, args                  = testArgs
					, template              = "notification"
					, resendOf              = ""
					, returnLogId           = false
					, overwriteTemplateArgs = false
					, isTest                = false
				};

				expectedSendArgs.append( testHandlerResult );

				mockColdBox.$( "runEvent" ).$results( testHandlerResult );
				emailService.$( "$getPresideSetting" ).$args( "email", "default_from_address" ).$results( testDefaultFrom );

				emailService.send(
					  template = "notification"
					, to       = testToAddresses
					, args     = testArgs
				);

				expect( mockServiceProviderService.$callLog().sendWithProvider.len() ).toBe( 1 );
				expect( mockServiceProviderService.$callLog().sendWithProvider[1] ).toBe( {
					  provider = defaultProvider
					, sendArgs = expectedSendArgs
					, logSend  = true
				} );
			} );

			it( "should throw an informative error when the passed template does not exist", function(){
				var emailService = _getEmailService();
				var errorThrown  = false;

				try {
					emailService.send( "someTemplateThatDoesNotExist" );
				} catch( "EmailService.missingTemplate" e ) {
					expect( e.message ?: "" ).toBe( "Missing email template [someTemplateThatDoesNotExist]"                                     );
					expect( e.detail  ?: "" ).toBe( "Expected to find a handler at [/handlers/emailTemplates/someTemplateThatDoesNotExist.cfc]" );
					errorThrown = true;
				} catch( any e ){
					fail( "Incorrect error thrown. Expected type [EmailService.missingTemplate] but error of type [#e.type#] was thrown instead with message [#e.message#]." );
				}

				expect( errorThrown ).toBe( true );
			} );

			it( "should throw informative error when no form address found", function(){
				var emailService = _getEmailService();
				var errorThrown  = false;

				emailService.$( "$getPresideSetting" ).$args( "email", "default_from_address" ).$results( "" );

				try {
					emailService.send( to=[ "test@test.com" ], subject="Test subject", htmlBody="not really html" );
				} catch( "EmailService.missingSender" e ) {
					expect( e.message ?: "" ).toBe( "Missing from email address when sending message with subject [Test subject]"                  );
					expect( e.detail  ?: "" ).toBe( "Ensure that a default from email address is configured through your Preside administrator" );
					errorThrown = true;
				} catch( any e ){
					fail( "Incorrect error thrown. Expected type [EmailService.missingSender] but error of type [#e.type#] was thrown instead with message [#e.message#]." );
				}

				expect( errorThrown ).toBe( true );
			} );

			it( "should throw an informative error when no to address found", function(){
				var emailService = _getEmailService();
				var errorThrown  = false;

				emailService.$( "$getPresideSetting" ).$args( "email", "default_from_address" ).$results( "" );

				try {
					emailService.send( from="test@test.com", subject="Test subject", htmlBody="not really html" );
				} catch( "EmailService.missingToAddress" e ) {
					expect( e.message ?: "" ).toBe( "Missing to email address(es) when sending message with subject [Test subject]" );
					errorThrown = true;
				} catch( any e ){
					fail( "Incorrect error thrown. Expected type [EmailService.missingToAddress] but error of type [#e.type#] was thrown instead with message [#e.message#]." );
				}

				expect( errorThrown ).toBe( true );
			} );

			it( "should thrown an informative error when no subject found", function(){
				var emailService = _getEmailService();
				var errorThrown  = false;

				emailService.$( "$getPresideSetting" ).$args( "email", "default_from_address" ).$results( "" );

				try {
					emailService.send( from="test@test.com", subject="Test subject", htmlBody="not really html" );
				} catch( "EmailService.missingToAddress" e ) {
					expect( e.message ?: "" ).toBe( "Missing to email address(es) when sending message with subject [Test subject]" );
					errorThrown = true;
				} catch( any e ){
					fail( "Incorrect error thrown. Expected type [EmailService.missingToAddress] but error of type [#e.type#] was thrown instead with message [#e.message#]." );
				}

				expect( errorThrown ).toBe( true );
			} );

			it( "should throw an informative error when no BODY found", function(){
				var emailService = _getEmailService();
				var errorThrown  = false;

				emailService.$( "$getPresideSetting" ).$args( "email", "default_from_address" ).$results( "" );

				try {
					emailService.send( from="from@test.com", to=["to@test.com"], subject="This is the subject" );
				} catch( "EmailService.missingBody" e ) {
					expect( e.message ?: "" ).toBe( "Missing body when sending message with subject [This is the subject]" );
					errorThrown = true;
				} catch( any e ){
					fail( "Incorrect error thrown. Expected type [EmailService.missingBody] but error of type [#e.type#] was thrown instead with message [#e.message#]." );
				}

				expect( errorThrown ).toBe( true );
			} );

			it( "should override template 'from' and 'subject' args when explicitly passed to send() method", function(){
				var emailService      = _getEmailService();
				var testToAddresses   = [ "dominic.watson@test.com", "another.test.com" ];
				var testArgs          = { some="test", data=true, template="notification" };
				var testHandlerResult = { from="someone@test.com", cc="someoneelse@test.com", htmlBody="test body", subject="This is a subject" };
				var overrideSubject   = CreateUUId();
				var overrideFrom      = CreateUUId() & "@test.com";
				var expectedSendArgs  = {
					  from                  = ""
					, recipientId           = ""
					, subject               = ""
					, to                    = testToAddresses
					, cc                    = []
					, bcc                   = []
					, replyto               = []
					, failto                = []
					, htmlBody              = ""
					, textBody              = ""
					, params                = {}
					, template              = "notification"
					, resendOf              = ""
					, returnLogId           = false
					, overwriteTemplateArgs = false
					, args                  = testArgs
					, isTest                = false
				};

				expectedSendArgs.append( testHandlerResult );
				expectedSendArgs.from    = overrideFrom;
				expectedSendArgs.subject = overrideSubject;

				mockColdBox.$( "runEvent" ).$results( testHandlerResult );

				emailService.send(
					  template = "notification"
					, to       = testToAddresses
					, args     = testArgs
					, subject  = overrideSubject
					, from     = overrideFrom
				);

				expect( mockServiceProviderService.$callLog().sendWithProvider.len() ).toBe( 1 );
				expect( mockServiceProviderService.$callLog().sendWithProvider[1] ).toBe( {
					  provider = defaultProvider
					, sendArgs = expectedSendArgs
					, logSend  = true
				} );
			} );

			it( "should announce onPrepareEmailSendArguments interception", function(){
				var emailService      = _getEmailService();
				var testToAddresses   = [ "dominic.watson@test.com", "another.test.com" ];
				var testArgs          = { some="test", data=true, template="notification" };

				mockColdBox.$( "runEvent" ).$results( { from="someone@test.com", cc="someoneelse@test.com", htmlBody="test body", subject="This is a subject" } );

				emailService.send(
					  template = "notification"
					, to       = testToAddresses
					, args     = testArgs
				);

				expect( emailService.$callLog().$announceInterception.len() ).toBe( 1 );
				expect( emailService.$callLog().$announceInterception[1][1] ).toBe( "onPrepareEmailSendArguments" );
				expect( emailService.$callLog().$announceInterception[1][2].keyExists( "sendArgs") ).toBeTrue();
			} );

		} );
	}


	private any function _getEmailService() output=false {
		templateDirs               = [ "/tests/resources/emailService/folder1", "/tests/resources/emailService/folder2", "/tests/resources/emailService/folder3" ]
		mockColdBox                = createMock( "preside.system.coldboxModifications.Controller" );
		mockEmailTemplateService   = createMock( "preside.system.services.email.EmailTemplateService" );
		mockServiceProviderService = createMock( "preside.system.services.email.EmailServiceProviderService" );
		
		mockTemplate = createStub();
		
		mockEmailTemplateService.$( "getTemplate" ).$results( mockTemplate );
		mockEmailTemplateService.$( "$isFeatureEnabled" ).$args( "emailOverwriteDomain" ).$results( false );
		mockEmailTemplateService.$( "enableDomainOverwriteForBuildLink" );

		var service = createMock( object=new preside.system.services.email.EmailService(
			  emailTemplateDirectories    = templateDirs
			, emailTemplateService        = mockEmailTemplateService
			, emailServiceProviderService = mockServiceProviderService
		) );

		service.$( "$getColdbox", mockColdbox );
		service.$( "$announceInterception" );
		mockEmailTemplateService.$( "templateExists", false );


		defaultProvider = CreateUUId();
		mockServiceProviderService.$( "getProviderForTemplate", defaultProvider );
		mockServiceProviderService.$( "sendWithProvider", true );

		return service;
	}

}