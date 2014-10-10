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

	function test08_getPageConfiguration_shouldReturnStructOfDataSpecifiedByConfigFormFromStoredConfigurationAndPageDefaults() output=false {
		var svc            = _getService();
		var testPage       = "memberarea.upgrade";
		var testFormName   = CreateUUId();
		var testFormFields = [ CreateUUId(), CreateUUId(), CreateUUId() ];
		var testValues     = { "#testFormFields[1]#" = CreateUUId(), "#testFormFields[3]#" = CreateUUId() };
		var testDefault    = CreateUUId();
		var testDbResult   = QueryNew( "setting_name,value", "varchar,varchar", [[ testFormFields[1], testValues[ testFormFields[1] ] ],[ testFormFields[3], testValues[ testFormFields[3] ] ] ] );
		var expected       = {
			  "#testFormFields[1]#" = testValues[ testFormFields[1] ]
			, "#testFormFields[2]#" = testDefault
			, "#testFormFields[3]#" = testValues[ testFormFields[3] ]
			, browser_title         = "This is my browser title"
		};

		svc.$( "getPageConfigFormName" ).$args( testPage ).$results( testFormName );
		mockFormService.$( "listFields" ).$args( testFormName ).$results( testFormFields );
		mockFormService.$( "getFormField" ).$args( testFormName, testFormFields[2] ).$results( { default=testDefault } );
		mockConfigStoreDao.$( "selectData" ).$args(
			  filter       = { page_id=testPage, setting_name=testFormFields }
			, selectFields = [ "setting_name", "value" ]
		).$results( testDbResult );


		super.assertEquals( expected, svc.getPageConfiguration( testPage ) );
	}

	function test09_getTree_shouldReturnAllTheApplicationPagesInATreeArray() output=false {
		var svc      = _getService();
		var expected = [{
			id       = "login",
			children = [{
				id       = "login.forgotPassword",
				children = [{
					id       = "login.forgotPassword.resetPassword",
					children = []
				}]
			}]
		},{
			id       = "memberarea",
			children = [{
				id       = "memberarea.editprofile",
				children = []
			},{
				id       = "memberarea.upgrade",
				children = []
			}]
		} ];

		svc.$( "getPageConfiguration", {} );

		super.assertEquals( expected, svc.getTree() );
	}

	function test10_savePageConfiguration_shouldSaveAllPageConfigurationSettings() output=false {
		var svc        = _getService();
		var testPage   = "memberarea.upgrade";
		var testConfig = {
			  setting_a = "value_a"
			, setting_b = "value_b"
			, setting_c = "value_c"
			, setting_d = "value_d"
			, setting_e = "value_e"
		};
		var testExistingConfig = {
			  setting_b = "old_value_b"
			, setting_e = "old_value_e"
		};

		svc.$( "getPageConfiguration", testExistingConfig );

		mockConfigStoreDao.$( "updateData" ).$args(
			  filter = { page_id=testPage, setting_name="setting_b" }
			, data   = { value=testConfig.setting_b }
		);
		mockConfigStoreDao.$( "updateData" ).$args(
			  filter = { page_id=testPage, setting_name="setting_e" }
			, data   = { value=testConfig.setting_e }
		);
		mockConfigStoreDao.$( "insertData" ).$args(
			data = { page_id=testPage, setting_name="setting_a", value=testConfig.setting_a }
		);
		mockConfigStoreDao.$( "insertData" ).$args(
			data = { page_id=testPage, setting_name="setting_c", value=testConfig.setting_c }
		);
		mockConfigStoreDao.$( "insertData" ).$args(
			data = { page_id=testPage, setting_name="setting_d", value=testConfig.setting_d }
		);

		svc.savePageConfiguration( id=testPage, config=testConfig );

		super.assertEquals( 2, mockConfigStoreDao.$callLog().updateData.len() );
		super.assertEquals( 3, mockConfigStoreDao.$callLog().insertData.len() );

	}

	function test11_getPageIdByHandler_shouldReturnEmptyString_whenNoPageMatchesTheGivenHandler() output=false {
		var svc = _getService();

		super.assertEquals( "", svc.getPageIdByHandler( "some.handler.that.does.not.map" ) );
	}

	function test12_getPageIdByHandler_shouldReturnIdOfPageWhosHandlerMatches() output=false {
		var svc = _getService();

		super.assertEquals( "memberarea.editprofile", svc.getPageIdByHandler( "test.editprofile" ) );
	}

	function test13_getAncestors_shouldReturnEmptyArray_whenPageDoesNotExist() output=false {
		var svc = _getService();

		super.assertEquals( [], svc.getAncestors( id="some.nonexistant.page" ) );
	}

	function test14_getAncestors_shouldReturnEmptyArray_whenPageHasNoAncestors() output=false {
		var svc = _getService();

		super.assertEquals( [], svc.getAncestors( id="memberarea" ) );
	}

	function test14_getAncestors_shouldReturnArrayOfPagesThatAreAncestorsOfThePassedInPage() output=false {
		var svc                       = _getService();
		var dummyLoginConfig          = { test="test login"  };
		var dummyForgotPasswordConfig = { test="test forgot" };
		var expected                  = [{
			  id      = "login.forgotPassword"
			, handler = "login.forgotPassword"
			, config  = dummyForgotPasswordConfig
		},{
			  id            = "login"
			, handler       = "login"
			, siteTemplates = [ "default","test","another" ]
			, config        = dummyLoginConfig
		}]

		svc.$( "getPageConfiguration" ).$args( "login"                ).$results( dummyLoginConfig          );
		svc.$( "getPageConfiguration" ).$args( "login.forgotPassword" ).$results( dummyForgotPasswordConfig );

		var actual = svc.getAncestors( id="login.forgotPassword.resetPassword" );

		super.assertEquals( expected, actual );
	}

	function test15_isPageAvailableInActiveSiteTemplate_shouldReturnFalse_whenPagesSiteTemplateListDoesNotContainActiveTemplate() output=false {
		var svc = _getService();

		mockSiteService.$( "getActiveSiteTemplate", "some-template" );

		super.assertFalse( svc.isPageAvailableInActiveSiteTemplate( "login" ) );
	}

	function test16_isPageAvailableInActiveSiteTemplate_shouldReturnTrue_whenPagesSiteTemplateListContainsActiveTemplate() output=false {
		var svc = _getService();

		mockSiteService.$( "getActiveSiteTemplate", "test" );

		super.assert( svc.isPageAvailableInActiveSiteTemplate( "login" ) );
	}

	function test17_isPageAvailableInActiveSiteTemplate_shouldReturnFalse_whenNoTemplatesConfiguredButParentPageRestrictsAccess() output=false {
		var svc = _getService();

		mockSiteService.$( "getActiveSiteTemplate", "some-template" );
		svc.$( "getPageConfiguration", {} );

		super.assertFalse( svc.isPageAvailableInActiveSiteTemplate( "login.forgotPassword.resetPassword" ) );
	}

	function test18_isPageAvailableInActiveSiteTemplate_shouldReturnTrue_whenNoTemplatesConfiguredButParentPageAllowsAccess() output=false {
		var svc = _getService();

		mockSiteService.$( "getActiveSiteTemplate", "test" );
		svc.$( "getPageConfiguration", {} );

		super.assert( svc.isPageAvailableInActiveSiteTemplate( "login.forgotPassword.resetPassword" ) );
	}

	function test19_isPageAvailableInActiveSiteTemplate_shouldReturnTrue_whenNoTemplatesConfiguredButParentPageAllowsAccess() output=false {
		var svc = _getService();

		mockSiteService.$( "getActiveSiteTemplate", "test" );
		svc.$( "getPageConfiguration", {} );

		super.assert( svc.isPageAvailableInActiveSiteTemplate( "login.forgotPassword.resetPassword" ) );
	}

	function test20_isPageAvailableInActiveSiteTemplate_shouldReturnTrue_whenNoTemplatesConfiguredButParentPageHasWildcardAccessDefined() output=false {
		var svc = _getService();

		mockSiteService.$( "getActiveSiteTemplate", "test" );
		svc.$( "getPageConfiguration", {} );

		super.assert( svc.isPageAvailableInActiveSiteTemplate( "memberarea.upgrade" ) );
	}

	function test21_isPageAvailableInActiveSiteTemplate_shouldReturnTrue_whenNoTemplatesConfiguredAnywhereInTheTree() output=false {
		var svc = _getService( config={
			login = {
				handler = "login",
				children = {
					forgotPassword = { handler="login.forgotpassword", children={
						resetPassword = { handler="test.resetPassword" }
					} }
				}
			}
		} );

		mockSiteService.$( "getActiveSiteTemplate", "test" );
		svc.$( "getPageConfiguration", {} );

		super.assert( svc.isPageAvailableInActiveSiteTemplate( "login.forgotPassword.resetPassword" ) );
	}

	function test22_isPageAvailableInActiveSiteTemplate_shouldReturnTrue_whenActiveSiteTemplateIsBlank() output=false {
		var svc = _getService();

		mockSiteService.$( "getActiveSiteTemplate", "" );

		super.assert( svc.isPageAvailableInActiveSiteTemplate( "memberarea.upgrade" ) );
	}

	function test23_getTree_shouldNotIncludePagesThatAreNotAvailableToTheCurrentSiteTemplate() output=false {
		var svc = _getService();
		var expected = [{
			id       = "memberarea",
			children = [{
				id       = "memberarea.editprofile",
				children = []
			},{
				id       = "memberarea.upgrade",
				children = []
			}]
		} ];

		svc.$( "getPageConfiguration", {} );
		mockSiteService.$( "getActiveSiteTemplate", "a-new-template" );


		super.assertEquals( expected, svc.getTree() );
	}


// PRIVATE HELPERS
	private any function _getService( struct config=_getDefaultTestApplicationPageConfiguration() ) output=false {
		mockFormService    = getMockBox().createEmptyMock( "preside.system.services.forms.FormsService" );
		mockSiteService    = getMockBox().createEmptyMock( "preside.system.services.siteTree.SiteService" );
		mockConfigStoreDao = getMockBox().createStub();

		mockSiteService.$( "getActiveSiteTemplate", "default" );

		return getMockBox().createMock( object = new preside.system.services.applicationPages.ApplicationPagesService(
			  configuredPages = arguments.config
			, formsService    = mockFormService
			, siteService     = mockSiteService
			, pageConfigDao   = mockConfigStoreDao
		) );
	}

	private struct function _getDefaultTestApplicationPageConfiguration() output=false {
		return {
			login = {
				handler = "login",
				siteTemplates = [ "default","test","another" ],
				children = {
					forgotPassword = { handler="login.forgotpassword", children={
						resetPassword = { handler="test.resetPassword" }
					} }
				}
			},
			memberarea = {
				handler = "members",
				sitetemplates=[ "*" ],
				children = {
					editprofile = { handler="test.editprofile" },
					upgrade     = { handler="members.upgrade", defaults={ browser_title="This is my browser title" } }
				}
			}
		};
	}

}