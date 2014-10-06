component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// TESTS
	function test01_listPages_shouldReturnArrayOfConfiguredApplicationPages() output=false {
		var svc      = _getService();
		var expected = [ "login", "login.forgotpassword", "login.forgotpassword.resetpassword", "memberarea", "memberarea.editprofile", "memberarea.upgrade" ];
		var actual   = svc.listPages();

		actual.sort( "textNoCase" );
		expected.sort( "textNoCase" );

		super.assertEquals( expected, actual );
	}

	function test02_getPage_shouldReturnDetailsOfRegisteredPage() output=false {
		var svc      = _getService();
		var expected = { handler="test.resetPassword" }
		var actual   = svc.getPage( id="login.forgotpassword.resetpassword" );

		super.assertEquals( expected, actual );
	}

	function test03_getPage_shouldThrowInformativeError_whenPageDoesNotExist() output=false {
		var svc         = _getService();
		var errorThrown = false;

		try {
			svc.getPage( id="some.nonexistant.page" );
		} catch( "ApplicationPagesService.page.notfound" e ) {
			super.assertEquals( "The application page, [some.nonexistant.page], is not registered with the system.", e.message );
			errorThrown = true;
		} catch ( any e ){}

		super.assert( errorThrown, "An informative error was not thrown" );
	}

	function test04_pageExists_shouldReturnFalse_whenPageIsNotConfigured() output=false {
		var svc = _getService();
		super.assertFalse( svc.pageExists( id="some.page" ) );
	}

	function test05_pageExists_shouldReturnTrue_whenPageIsConfigured() output=false {
		var svc = _getService();
		super.assert( svc.pageExists( "memberarea" ) );
	}

	function test06_getPageConfigFormName_shouldReturnDefaultFormOnly_whenNoSpecificFormExistsForThePageType() output=false {
		var svc = _getService();
		var testPage = "members.upgrade";

		mockFormService.$( "formExists" ).$args( "application-pages.#testPage#" ).$results( false );

		super.assertEquals( "application-pages.default", svc.getPageConfigFormName( id=testPage ) );
	}

	function test07_getPageConfigFormName_shouldReturnMergedFormName_whenCustomFormExistsForPage() output=false {
		var svc                = _getService();
		var testPage           = "members.upgrade";
		var testMergedFormName = CreateUUId();

		mockFormService.$( "formExists" ).$args( "application-pages.#testPage#" ).$results( true );
		mockFormService.$( "getMergedFormName" ).$args( "application-pages.default", "application-pages.#testPage#" ).$results( testMergedFormName );

		super.assertEquals( testMergedFormName, svc.getPageConfigFormName( id=testPage ) );
	}

// PRIVATE HELPERS
	private any function _getService( struct config=_getDefaultTestApplicationPageConfiguration() ) output=false {
		mockFormService = getMockBox().createEmptyMock( "preside.system.services.forms.FormsService" );

		return new preside.system.services.applicationPages.ApplicationPagesService(
			  configuredPages = arguments.config
			, formsService    = mockFormService
		);
	}

	private struct function _getDefaultTestApplicationPageConfiguration() output=false {
		return {
			login = {
				handler = "login",
				children = {
					forgotPassword = { handler="login.forgotpassword", children={
						resetPassword = { handler="test.resetPassword" }
					} }
				}
			},
			memberarea = {
				handler = "members",
				children = {
					editprofile = { handler="test.editprofile" },
					upgrade     = { handler="members.upgrade" }
				}
			}
		};
	}

}