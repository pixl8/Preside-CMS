component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// SETUP, TEARDOWN, ETC.
	function setup() {
		mockPresideObjectService = getMockbox().createEmptyMock( "preside.system.api.presideObjects.PresideObjectService" );
		mockLogger               = _getTestLogger();

		mockPresideObjectService.$( "objectExists" ).$results( true );
		testDirs = [ "/tests/resources/systemConfiguration/dir1", "/tests/resources/systemConfiguration/dir2", "/tests/resources/systemConfiguration/dir3" ];
	}

// TESTS
	function test01_listConfigCategories_shouldReturnEmptyArray_whenNoConfigurationCategoriesConfigured() {
		super.assertEquals( [], _getConfigSvc().listConfigCategories() );
	}

	function test02_listConfigCategories_shouldReturnAnArrayOfCategoriesThatHaveBeenAutoDiscoveredThroughTheConfiguredDirectories() {
		var expected     = [ "blog_settings", "client_settings", "mail_settings", "security_settings" ];
		var categories   = _getConfigSvc( testDirs ).listConfigCategories();
		var ids          = [];

		for( var cat in categories ){
			ArrayAppend( ids, cat.getid() );
		}

		ids.sort( "textnocase" );
		super.assertEquals( expected, ids );
	}

// PRIVATE HELPERS
	private any function _getConfigSvc( array autoDiscoverDirectories=[] ) ouput=false {
		return new preside.system.api.configuration.SystemConfigurationService(
			  presideObjectService    = mockPresideObjectService
			, logger                  = mockLogger
			, autoDiscoverDirectories = arguments.autoDiscoverDirectories
		);
	}
}