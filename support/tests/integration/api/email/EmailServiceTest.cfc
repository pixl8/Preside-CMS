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
		var expectedSendArgs  = { from="someone@test.com", to=testToAddresses, cc="someoneelse@test.com", htmlBody="test body", subject="This is a subject" };

		emailService.$( "_send", true );
		mockColdBox.$( "runEvent" ).$args( event="emailTemplates.notification.index", private=true, eventArguments={ args=testArgs } ).$results( testHandlerResult );

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