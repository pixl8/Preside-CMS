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


// private utility
	private any function _getSiteService() output=false {
		return new preside.system.services.sitetree.SiteService( siteDao=_getPresideObjectService().getObject( "site" ) );
	}

	private void function _setupTestData() output=false {
		variables.sites = [];

		sites.append( _insertData( objectName="site", data={ name="Default site" , domain="*"              , path="/"    } ) );
		sites.append( _insertData( objectName="site", data={ name="Test site"    , domain="testsite.com"   , path="*"    } ) );
		sites.append( _insertData( objectName="site", data={ name="Test site sub", domain="testsite.com"   , path="/sub" } ) );
		sites.append( _insertData( objectName="site", data={ name="Another site" , domain="anothersite.com", path="*"    } ) );
	}

	private void function _wipeTestData() output=false {
		_deleteData( objectName="site", forceDeleteAll=true );
	}
}