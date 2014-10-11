component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// TESTS
	function test01_isFeatureEnabled_shouldReturnFalse_whenFeatureDoesNotExist() output=false {
		var svc = _getService();

		super.assertFalse( svc.isFeatureEnabled( feature="somefeature" ) );
	}

	function test02_isFeatureEnabled_shouldReturnTrue_whenFeatureExistsAndIsEnabled() output=false {
		var svc = _getService();

		super.assert( svc.isFeatureEnabled( feature="datamanager" ) );
	}

	function test03_isFeatureEnabled_shouldReturnFalse_whenFeatureExistsAndIsDisabled() output=false {
		var svc = _getService();

		super.assertFalse( svc.isFeatureEnabled( feature="sitetree" ) );
	}

	function test04_isFeatureEnabled_shouldReturnFalse_whenFeatureIsEnabledButNotForTheCurrentSiteTemplate() output=false {
		var svc = _getService();

		mockSiteService.$( "getActiveSiteTemplate", "somesite" );
		super.assertFalse( svc.isFeatureEnabled( feature="sites" ) );
	}

	function test05_isFeatureEnabled_shouldReturnTrue_whenFeatureHasDefaultTemplateSet_andCurrentTemplateIsBlank() output=false {
		var svc = _getService();

		mockSiteService.$( "getActiveSiteTemplate", "" );
		super.assert( svc.isFeatureEnabled( feature="sites" ) ) ;
	}

// PRIVATE HELPERS
	private any function _getService( struct config=_getDefaultTestConfiguration() ) output=false {
		mockSiteService = getMockBox().createEmptyMock( "preside.system.services.siteTree.SiteService" );
		mockSiteService.$( "getActiveSiteTemplate", "default" );

		return getMockBox().createMock( object = new preside.system.services.features.FeatureService(
			  configuredFeatures = arguments.config
			, siteService        = mockSiteService
		) );
	}

	private struct function _getDefaultTestConfiguration() output=false {
		return {
			  sitetree     = { enabled=false, siteTemplates=[ "*" ] }
			, sites        = { enabled=true , siteTemplates=[ "tempate-x", "template-y", "default" ] }
			, assetManager = { enabled=false, siteTemplates=[ "*" ] }
			, websiteUsers = { enabled=true }
			, datamanager  = { enabled=true,  siteTemplates=[ "*" ] }
		};
	}
}