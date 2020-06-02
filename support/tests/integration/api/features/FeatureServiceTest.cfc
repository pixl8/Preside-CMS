component extends="testbox.system.BaseSpec"{

	function run(){
		describe( "isFeatureEnabled()", function(){
			it( "should return false when feature does not exist", function(){
				var svc = _getService();
				expect( svc.isFeatureEnabled( feature="somefeature" ) ).toBe( false );
			} );

			it( "should return true when feature exists and is enabled", function(){
				var svc = _getService();

				expect( svc.isFeatureEnabled( feature="datamanager" ) ).toBeTrue();
			} );

			it( "should return false when feature exists and is disabled", function(){
				var svc = _getService();

				expect( svc.isFeatureEnabled( feature="sitetree" ) ).toBeFalse();
			} );

			it( "should return false when feature is enabled but not for the passed site template", function(){
				var svc = _getService();

				expect( svc.isFeatureEnabled( feature="sites", siteTemplate="somesiteTemplate" ) ).toBeFalse();
			} );

			it( "should return true when feature has default template set and current template is blank", function(){
				var svc = _getService();

				mockSiteService.$( "getActiveSiteTemplate", "" );
				expect( svc.isFeatureEnabled( feature="sites", siteTemplate="" ) ) .toBeTrue();
			} );

		} );

		describe( "isFeatureDefined()", function(){
			it( "should return false when feature is not defined at all", function(){
				var svc = _getService();

				mockSiteService.$( "getActiveSiteTemplate", "" );
				expect( svc.isFeatureDefined( "somefeature" ) ).toBeFalse();
			} );

			it( "should return true when feature is defined", function(){
				var svc = _getService();

				mockSiteService.$( "getActiveSiteTemplate", "" );
				expect( svc.isFeatureDefined( "sitetree" ) ).toBeTrue();
			} );
		} );

		describe( "getFeatureForWidget", function(){
			it( "should return empty string when widget does not belong to a feature", function(){
				var svc = _getService();

				expect( svc.getFeatureForWidget( "somewidget" ) ).toBe( "" );
			} );

			it( "should pass the id of the feauture to which the widget belongs", function(){
				var svc = _getService();

				expect( svc.getFeatureForWidget( "datajazzwidget" ) ).toBe( "datamanager" );
			} );
		} );


	}


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
			, datamanager  = { enabled=true,  siteTemplates=[ "*" ], widgets=[ "datajazzwidget" ] }
		};
	}
}