component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// tests
	function test01_listTemplates_shouldReturnListOfTemplatesThatHaveBeenScannedFromConventionBasedFolderUnderHandlers() output=false {
		var emailService      = _getEmailService();
		var expectedTemplates = [ "notification", "resetAdminPassword", "resetWebsitePassword" ];

		super.assertEquals( expectedTemplates, emailService.listTemplates() );
	}

	function test02_send_shouldRunTemplateHandlerToMixInVariablesThatAreThenForwardedToTheCFMailCall() output=false {
		var emailService      = _getEmailService();
		var testToAddresses   = [ "dominic.watson@test.com", "another.test.com" ];
		var testArgs          = { some="test", data=true };
		var testHandlerResult = { from="someone@test.com", cc="someoneelse@test.com", htmlBody="test body", subject="This is a subject" };
		var expectedSendArgs  = {
			  from     = ""
			, subject  = ""
			, to       = testToAddresses
			, cc       = []
			, bcc      = []
			, htmlBody = ""
			, textBody = ""
			, params   = {}
		};

		expectedSendArgs.append( testHandlerResult );


		emailService.$( "_send", true );

		mockColdBox.$( "runEvent" ).$results( testHandlerResult );

		emailService.send(
			  template = "notification"
			, to       = testToAddresses
			, args     = testArgs
		);

		super.assertEquals( 1, emailService.$callLog()._send.len() );
		super.assertEquals( expectedSendArgs, emailService.$callLog()._send[1] );
	}

	function test03_send_shouldUseDefaultFromEmailSetting_whenNoFromAddressIsReturnedFromTheTemplateHandler() output=false {
		var emailService      = _getEmailService();
		var testToAddresses   = [ "dominic.watson@test.com", "another@test.com" ];
		var testArgs          = { some="test", data=true };
		var testHandlerResult = { cc="someoneelse@test.com", htmlBody="test body", subject="This is a subject" };
		var testDefaultFrom   = "default@test.com";
		var expectedSendArgs  = {
			  from     = testDefaultFrom
			, subject  = ""
			, to       = testToAddresses
			, cc       = []
			, bcc      = []
			, htmlBody = ""
			, textBody = ""
			, params   = {}
		};

		expectedSendArgs.append( testHandlerResult );

		emailService.$( "_send", true );
		mockColdBox.$( "runEvent" ).$results( testHandlerResult );
		mockSystemConfigurationService.$( "getSetting" ).$args( "email", "default_from_address" ).$results( testDefaultFrom );

		emailService.send(
			  template = "notification"
			, to       = testToAddresses
			, args     = testArgs
		);

		super.assertEquals( 1, emailService.$callLog()._send.len() );
		super.assertEquals( expectedSendArgs, emailService.$callLog()._send[1] );
	}

	function test04_send_shouldThrowAnInformativeError_whenThePassedTemplateDoesNotExist() output=false {
		var emailService = _getEmailService();
		var errorThrown  = false;

		try {
			emailService.send( "someTemplateThatDoesNotExist" );
		} catch( "EmailService.missingTemplate" e ) {
			super.assertEquals( "Missing email template [someTemplateThatDoesNotExist]", e.message ?: "" );
			super.assertEquals( "Expected to find a handler at [/handlers/emailTemplates/someTemplateThatDoesNotExist.cfc]", e.detail  ?: "" );
			errorThrown = true;
		} catch( any e ){
			super.fail( "Incorrect error thrown. Expected type [EmailService.missingTemplate] but error of type [#e.type#] was thrown instead with message [#e.message#]." );
		}

		super.assert( errorThrown, "An informative error was not thrown" );
	}

	function test05_send_shouldThrowInformativeError_whenNoFromAddressFound() output=false {
		var emailService = _getEmailService();
		var errorThrown  = false;

		emailService.$( "_send", true );
		mockSystemConfigurationService.$( "getSetting" ).$args( "email", "default_from_address" ).$results( "" );

		try {
			emailService.send( to=[ "test@test.com" ], subject="Test subject", htmlBody="not really html" );
		} catch( "EmailService.missingSender" e ) {
			super.assertEquals( "Missing from email address when sending message with subject [Test subject]", e.message ?: "" );
			super.assertEquals( "Ensure that a default from email address is configured through your PresideCMS administrator", e.detail  ?: "" );
			errorThrown = true;
		} catch( any e ){
			super.fail( "Incorrect error thrown. Expected type [EmailService.missingSender] but error of type [#e.type#] was thrown instead with message [#e.message#]." );
		}

		super.assert( errorThrown, "An informative error was not thrown" );
	}

	function test06_send_shouldThrowInformativeError_whenNoToAddressesFound() output=false {
		var emailService = _getEmailService();
		var errorThrown  = false;

		emailService.$( "_send", true );
		mockSystemConfigurationService.$( "getSetting" ).$args( "email", "default_from_address" ).$results( "" );

		try {
			emailService.send( from="test@test.com", subject="Test subject", htmlBody="not really html" );
		} catch( "EmailService.missingToAddress" e ) {
			super.assertEquals( "Missing to email address(es) when sending message with subject [Test subject]", e.message ?: "" );
			errorThrown = true;
		} catch( any e ){
			super.fail( "Incorrect error thrown. Expected type [EmailService.missingToAddress] but error of type [#e.type#] was thrown instead with message [#e.message#]." );
		}

		super.assert( errorThrown, "An informative error was not thrown" );
	}

	function test07_send_shouldThrowInformativeError_whenNoSubjectFound() output=false {
		var emailService = _getEmailService();
		var errorThrown  = false;

		emailService.$( "_send", true );
		mockSystemConfigurationService.$( "getSetting" ).$args( "email", "default_from_address" ).$results( "" );

		try {
			emailService.send( from="from@test.com", to=["to@test.com"], htmlBody="not really html" );
		} catch( "EmailService.missingSubject" e ) {
			super.assertEquals( "Missing subject when sending message to [to@test.com], from [from@test.com]", e.message ?: "" );
			errorThrown = true;
		} catch( any e ){
			super.fail( "Incorrect error thrown. Expected type [EmailService.missingSubject] but error of type [#e.type#] was thrown instead with message [#e.message#]." );
		}

		super.assert( errorThrown, "An informative error was not thrown" );
	}

	function test08_send_shouldThrowInformativeError_whenNoBodyFound() output=false {
		var emailService = _getEmailService();
		var errorThrown  = false;

		emailService.$( "_send", true );
		mockSystemConfigurationService.$( "getSetting" ).$args( "email", "default_from_address" ).$results( "" );

		try {
			emailService.send( from="from@test.com", to=["to@test.com"], subject="This is the subject" );
		} catch( "EmailService.missingBody" e ) {
			super.assertEquals( "Missing body when sending message with subject [This is the subject]", e.message ?: "" );
			errorThrown = true;
		} catch( any e ){
			super.fail( "Incorrect error thrown. Expected type [EmailService.missingBody] but error of type [#e.type#] was thrown instead with message [#e.message#]." );
		}

		super.assert( errorThrown, "An informative error was not thrown" );
	}

// private helpers
	private any function _getEmailService() output=false {
		templateDirs                   = [ "/tests/resources/emailService/folder1", "/tests/resources/emailService/folder2", "/tests/resources/emailService/folder3" ];
		mockColdBox                    = getMockBox().createMock( "preside.system.coldboxModifications.Controller" );
		mockSystemConfigurationService = getMockBox().createMock( "preside.system.services.configuration.SystemConfigurationService" );

		return getMockBox().createMock( object=new preside.system.services.email.EmailService(
			  emailTemplateDirectories   = templateDirs
			, coldbox                    = mockColdBox
			, systemConfigurationService = mockSystemConfigurationService
		) );
	}

}