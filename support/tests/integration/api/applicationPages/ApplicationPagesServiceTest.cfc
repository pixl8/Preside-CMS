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