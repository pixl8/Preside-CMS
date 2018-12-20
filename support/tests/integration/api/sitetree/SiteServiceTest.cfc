component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function beforeAll() {
		_emptyDatabase();

		presideObjectService = _getPresideObjectService( forceNewInstance=true );
		presideObjectService.dbSync();

		_setupTestData();
	}

	function run() {

		describe( "matchSite()", function(){
			it( "should return default site when no specific matches made", function(){
				var siteService = _getSiteService();
				var site        = siteService.matchSite( domain="anyolddomain.com", path="/anyoldpath.html" );

				expect( site.id ?: "" ).toBe( sites[1] );
			} );

			it( "should return default site when domain matched but not paths match", function(){
				var siteService = _getSiteService();
				var site        = siteService.matchSite( domain="www.oddsite.com", path="/anyoldpath.html" );

				expect( site.id ?: "" ).toBe( sites[1] );
			} );

			it( "should return specific stie that matches domain when no specific paths registered for that domain", function(){
				var siteService = _getSiteService();
				var site        = siteService.matchSite( domain="fubar.anothersite.com", path="/some/path/" );

				expect( site.id ?: "" ).toBe( sites[4] );
			} );

			it( "should return specific site that matches domain and path when specific paths registered for that domain", function(){
				var siteService = _getSiteService();
				var site        = siteService.matchSite( domain="testsite.com", path="/sub/path/" );

				expect( site.id ?: "" ).toBe( sites[3] );
			} );

			it( "should return specific site that matches just domain when both general and specific path registerd but specific path not matches", function(){
				var siteService = _getSiteService();
				var site        = siteService.matchSite( domain="testsite.com", path="/any/old/path.html" );

				expect( site.id ?: "" ).toBe( sites[2] );
			} );
		} );

		describe( "getActiveAdminSite()", function(){
			it( "should return active site stored in session when user has permisission to navigate to it", function(){
				var siteService = _getSiteService();
				var testSiteId  = "testsiteid";

				mockSessionStorage.$( "exists" ).$args( "_activeSite" ).$results( true );
				mockSessionStorage.$( "getVar" ).$args( "_activeSite" ).$results( { id=testSiteId } );
				mockPermissionService.$( "hasPermission" ).$args( permissionKey="sites.navigate", context="site", contextKeys=[ testSiteId ] ).$results( true );

				expect( siteService.getActiveAdminSite( domain="testsite.com" ).id ).toBe( testSiteId );
			} );

			it( "should return first site matching the current domain that user has access to when no active site already set", function(){
				var siteService = _getSiteService();

				mockSessionStorage.$( "exists" ).$args( "_activeSite" ).$results( false );
				mockSessionStorage.$( "setVar", NullValue() );

				mockPermissionService.$( "hasPermission" ).$args( permissionKey="sites.navigate", context="site", contextKeys=[ sites[1] ] ).$results( true );
				mockPermissionService.$( "hasPermission" ).$args( permissionKey="sites.navigate", context="site", contextKeys=[ sites[2] ] ).$results( true );
				mockPermissionService.$( "hasPermission" ).$args( permissionKey="sites.navigate", context="site", contextKeys=[ sites[3] ] ).$results( true );
				mockPermissionService.$( "hasPermission" ).$args( permissionKey="sites.navigate", context="site", contextKeys=[ sites[4] ] ).$results( false );
				mockPermissionService.$( "hasPermission" ).$args( permissionKey="sites.navigate", context="site", contextKeys=[ sites[5] ] ).$results( true );

				expect( siteService.getActiveAdminSite( domain="testsite.com" ).id ).toBe( sites[2] );
			} );
		} );
	}

// private utility
	private any function _getSiteService() {
		mockSessionStorage    = createStub();
		mockPermissionService = createStub();
		mockColdbox           = createEmptyMock( "preside.system.coldboxModifications.Controller" );

		var svc = createMock( object=CreateObject( "preside.system.services.sitetree.SiteService" ) )
		svc.$( "$isFeatureEnabled", true );

		return svc.init(
			  siteDao               = presideObjectService.getObject( "site" )
			, siteAliasDomainDao    = presideObjectService.getObject( "site_alias_domain" )
			, siteRedirectDomainDao = presideObjectService.getObject( "site_redirect_domain" )
			, sessionStorage        = mockSessionStorage
			, permissionService     = mockPermissionService
			, coldbox               = mockColdbox
		);
	}

	private void function _setupTestData() {
		variables.sites = [];

		sites.append( _insertData( objectName="site", data={ name="Default site" , domain="*"                    , path="/"          } ) );
		sites.append( _insertData( objectName="site", data={ name="Test site"    , domain="testsite.com"         , path="/"          } ) );
		sites.append( _insertData( objectName="site", data={ name="Test site sub", domain="testsite.com"         , path="/sub"       } ) );
		sites.append( _insertData( objectName="site", data={ name="Another site" , domain="fubar.anothersite.com", path="/"          } ) );
		sites.append( _insertData( objectName="site", data={ name="An odd site"  , domain="www.oddsite.com"      , path="/specific"  } ) );
	}
}