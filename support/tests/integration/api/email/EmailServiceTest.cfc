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
			  from          = ""
			, subject       = ""
			, to            = testToAddresses
			, cc            = []
			, bcc           = []
			, htmlBody      = ""
			, plainTextBody = ""
			, params        = {}
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
			  from          = testDefaultFrom
			, subject       = ""
			, to            = testToAddresses
			, cc            = []
			, bcc           = []
			, htmlBody      = ""
			, plainTextBody = ""
			, params        = {}
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

// private helpers
	private any function _getEmailService() output=false {
		templateDirs                   = [ "/tests/resources/emailService/folder1", "/tests/resources/emailService/folder2", "/tests/resources/emailService/folder3" ]
		mockColdBox                    = getMockBox().createMock( "preside.system.coldboxModifications.Controller" );
		mockSystemConfigurationService = getMockBox().createMock( "preside.system.services.configuration.SystemConfigurationService" );

		return getMockBox().createMock( object=new preside.system.services.email.EmailService(
			  emailTemplateDirectories   = templateDirs
			, coldbox                    = mockColdBox
			, systemConfigurationService = mockSystemConfigurationService
		) );
	}

}