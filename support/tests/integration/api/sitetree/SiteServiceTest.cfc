component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {
// test lifecycle methods
	public any function beforeTests() output=false {
		_emptyDatabase();
		_dbSync();
		_wipeTestData();
		_setupTestData();
	}

// tests
	public void function test01_matchSite_shouldReturnDefaultSite_whenNoSpecificMatchesMade() output=false {
		var siteService = _getSiteService();
		var site        = siteService.matchSite( domain="anyolddomain.com", path="/anyoldpath.html" );

		super.assertEquals( sites[1], site.id ?: "" );
	}

	public void function test02_matchSite_shouldReturnDefaultSite_whenDomainMatchedButNoPathsMatch() output=false {
		var siteService = _getSiteService();
		var site        = siteService.matchSite( domain="www.oddsite.com", path="/anyoldpath.html" );

		super.assertEquals( sites[1], site.id ?: "" );
	}

	public void function test03_matchSite_shouldReturnSpecificSiteThatMatchesDomain_whenNoSpecificPathsRegisteredForThatDomain() output=false {
		var siteService = _getSiteService();
		var site        = siteService.matchSite( domain="fubar.anothersite.com", path="/some/path/" );

		super.assertEquals( sites[4], site.id ?: "" );
	}

	public void function test04_matchSite_shouldReturnSpecificSiteThatMatchesDomainAndPath_whenSpecificPathsRegisteredForThatDomain() output=false {
		var siteService = _getSiteService();
		var site        = siteService.matchSite( domain="testsite.com", path="/sub/path/" );

		super.assertEquals( sites[3], site.id ?: "" );
	}

	public void function test05_matchSite_shouldReturnSpecificSiteThatMatchesJustDomain_whenBothGeneralAndSpecificPathRegisteredButSpecificPathNotMatches() output=false {
		var siteService = _getSiteService();
		var site        = siteService.matchSite( domain="testsite.com", path="/any/old/path.html" );

		super.assertEquals( sites[2], site.id ?: "" );
	}

	public void function test06_getActiveAdminSite_shouldReturnActiveSiteStoredInSession_whenUserHasPermissionToNavigateIt() output=false {
		var siteService = _getSiteService();
		var testSiteId  = "testsiteid";

		mockSessionStorage.$( "exists" ).$args( "_activeSite" ).$results( true );
		mockSessionStorage.$( "getVar" ).$args( "_activeSite" ).$results( { id=testSiteId } );
		mockPermissionService.$( "hasPermission" ).$args( permissionKey="sites.navigate", context="site", contextKeys=[ testSiteId ] ).$results( true );

		super.assertEquals( testSiteId, siteService.getActiveAdminSite().id );
	}

	public void function test07_getActiveAdminSite_shouldReturnFirstSiteThatUserHasAccessTo_whenNoActiveSiteAlreadySet() output=false {
		var siteService = _getSiteService();

		mockSessionStorage.$( "exists" ).$args( "_activeSite" ).$results( false );
		mockSessionStorage.$( "setVar", NullValue() );

		mockPermissionService.$( "hasPermission" ).$args( permissionKey="sites.navigate", context="site", contextKeys=[ sites[1] ] ).$results( false );
		mockPermissionService.$( "hasPermission" ).$args( permissionKey="sites.navigate", context="site", contextKeys=[ sites[2] ] ).$results( true );
		mockPermissionService.$( "hasPermission" ).$args( permissionKey="sites.navigate", context="site", contextKeys=[ sites[3] ] ).$results( true );
		mockPermissionService.$( "hasPermission" ).$args( permissionKey="sites.navigate", context="site", contextKeys=[ sites[4] ] ).$results( false );
		mockPermissionService.$( "hasPermission" ).$args( permissionKey="sites.navigate", context="site", contextKeys=[ sites[5] ] ).$results( true );

		super.assertEquals( sites[2], siteService.getActiveAdminSite().id );
	}

// private utility
	private any function _getSiteService() output=false {
		mockSessionStorage    = getMockBox().createStub();
		mockPermissionService = getMockBox().createStub();
		mockColdbox           = getMockbox().createEmptyMock( "preside.system.coldboxModifications.Controller" );

		return new preside.system.services.sitetree.SiteService(
			  siteDao           = _getPresideObjectService().getObject( "site" )
			, sessionStorage    = mockSessionStorage
			, permissionService = mockPermissionService
			, coldbox           = mockColdbox
		);
	}

	private void function _setupTestData() output=false {
		variables.sites = [];

		sites.append( _insertData( objectName="site", data={ name="Default site" , domain="*"                    , path="/"          } ) );
		sites.append( _insertData( objectName="site", data={ name="Test site"    , domain="testsite.com"         , path="/"          } ) );
		sites.append( _insertData( objectName="site", data={ name="Test site sub", domain="testsite.com"         , path="/sub"       } ) );
		sites.append( _insertData( objectName="site", data={ name="Another site" , domain="fubar.anothersite.com", path="/"          } ) );
		sites.append( _insertData( objectName="site", data={ name="An odd site"  , domain="www.oddsite.com"      , path="/specific"  } ) );
	}

	private void function _wipeTestData() output=false {
		_deleteData( objectName="site", forceDeleteAll=true );
	}
}