component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// tests
	function test01_listTemplates_shouldReturnListOfTemplatesThatHaveBeenScannedFromConventionBasedFolderUnderHandlers() output=false {
		var emailService      = _getEmailService();
		var expectedTemplates = [ "notification", "resetAdminPassword", "resetWebsitePassword" ];

		super.assertEquals( expectedTemplates, emailService.listTemplates() );
	}

// private helpers
	private any function _getEmailService() output=false {
		var templateDirs = [ "/tests/resources/emailService/folder1", "/tests/resources/emailService/folder2", "/tests/resources/emailService/folder3" ]
		var mailService  = new preside.system.services.email.EmailService( emailTemplateDirectories=templateDirs );

		return getMockBox().createMock( object=mailService );
	}

}