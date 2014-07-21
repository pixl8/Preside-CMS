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

		super.assertEquals( sites[1], site );
	}

	public void function test02_matchSite_shouldReturnDefaultSite_whenDomainMatchedButNoPathsMatch() output=false {
		var siteService = _getSiteService();
		var site        = siteService.matchSite( domain="www.oddsite.com", path="/anyoldpath.html" );

		super.assertEquals( sites[1], site );
	}

	public void function test03_matchSite_shouldReturnSpecificSiteThatMatchesDomain_whenNoSpecificPathsRegisteredForThatDomain() output=false {
		var siteService = _getSiteService();
		var site        = siteService.matchSite( domain="fubar.anothersite.com", path="/some/path/" );

		super.assertEquals( sites[4], site );
	}

	public void function test04_matchSite_shouldReturnSpecificSiteThatMatchesDomainAndPath_whenSpecificPathsRegisteredForThatDomain() output=false {
		var siteService = _getSiteService();
		var site        = siteService.matchSite( domain="testsite.com", path="/sub/path/" );

		super.assertEquals( sites[3], site );
	}

	public void function test05_matchSite_shouldReturnSpecificSiteThatMatchesJustDomain_whenBothGeneralAndSpecificPathRegisteredButSpecificPathNotMatches() output=false {
		var siteService = _getSiteService();
		var site        = siteService.matchSite( domain="testsite.com", path="/any/old/path.html" );

		super.assertEquals( sites[2], site );
	}

// private utility
	private any function _getSiteService() output=false {
		return new preside.system.services.sitetree.SiteService( siteDao=_getPresideObjectService().getObject( "site" ) );
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