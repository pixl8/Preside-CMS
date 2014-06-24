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

	function test03_getConfigCategory_shouldReturnConfigCategoryBeanForGivenCategory() {
		var cat = _getConfigSvc( testDirs ).getConfigCategory( id="blog_settings" );

		super.assertEquals( "system-config.blog_settings:name"       , cat.getName()        );
		super.assertEquals( "system-config.blog_settings:description", cat.getDescription() );
		super.assertEquals( "system-config.blog_settings"            , cat.getForm( )       );
	}

	function test04_getConfigCategory_shouldThrowInformativeError_whenCategoryDoesNotExist() {
		var errorThrown = false;

		try {
			_getConfigSvc( testDirs ).getConfigCategory( id="meh" );
		} catch( "SystemConfigurationService.category.notfound" e ){
			super.assertEquals( 'The configuration category [meh] could not be found. Configured categories are: ["blog_settings","client_settings","mail_settings","security_settings"]', e.message );
			errorThrown = true;
		} catch ( any e ) {}

		super.assert( errorThrown, "A suitable error was not thrown" );
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