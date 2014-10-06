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

// PRIVATE HELPERS
	private any function _getService( struct config=_getDefaultTestApplicationPageConfiguration() ) output=false {
		return new preside.system.services.applicationPages.ApplicationPagesService(
			configuredPages = arguments.config
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