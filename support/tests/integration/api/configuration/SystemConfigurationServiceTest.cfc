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

	function test05_saveSetting_shouldInsertANewDbRecord_whenNoExistingRecordExistsForTheGivenConfigKey() {
		mockPresideObjectService.$( "selectData" )
			.$args( objectName="system_config", filter={ category="mycategory", setting="mysetting" }, selectFields=["id"] )
			.$results( QueryNew('id') );

		mockPresideObjectService.$( "insertData", CreateUUId() );

		_getConfigSvc( testDirs ).saveSetting(
			  category = "mycategory"
			, setting  = "mysetting"
			, value    = "this is the value of my setting"
		);

		var log = mockPresideObjectService.$callLog().insertData;

		super.assertEquals( 1, log.len() );
		super.assertEquals( {
			  objectName = "system_config"
			, data       = { category="mycategory", setting="mysetting", value="this is the value of my setting" }
		}, log[1] );
	}

	function test06_saveSetting_shouldUpdateExistingDbRecord_whenRecordAlreadyExistsInDb() {
		mockPresideObjectService.$( "selectData" )
			.$args( objectName="system_config", filter={ category="mycategory", setting="mysetting" }, selectFields=["id"] )
			.$results( QueryNew('id', "varchar", ["someid"] ) );

		mockPresideObjectService.$( "insertData", CreateUUId() );
		mockPresideObjectService.$( "updateData", 1 );

		_getConfigSvc( testDirs ).saveSetting(
			  category = "mycategory"
			, setting  = "mysetting"
			, value    = "this is the value of my setting"
		);

		var log = mockPresideObjectService.$callLog().insertData;
		super.assertEquals( 0, log.len() );

		log = mockPresideObjectService.$callLog().updateData;
		super.assertEquals( 1, log.len() );
		super.assertEquals( {
			  objectName = "system_config"
			, data       = {  value="this is the value of my setting" }
			, id         = "someid"
		}, log[1] );
	}

	function test07_getSetting_shouldReturnValueAsSavedInTheDatabaseForGivenCategoryAndSetting() {
		mockPresideObjectService.$( "selectData" )
			.$args( objectName="system_config", filter={ category="somecategory", setting="asetting" }, selectFields=["value"] )
			.$results( QueryNew('value', "varchar", ["this is the correct result"] ) );

		super.assertEquals( "this is the correct result", _getConfigSvc( testDirs ).getSetting(
			  category = "somecategory"
			, setting  = "asetting"
		) );
	}

	function test08_getSetting_shouldReturnPassedDefault_whenNoRecordExists() {
		mockPresideObjectService.$( "selectData" )
			.$args( objectName="system_config", filter={ category="somecategory", setting="asetting" }, selectFields=["value"] )
			.$results( QueryNew('value') );

		super.assertEquals( "defaultResult", _getConfigSvc( testDirs ).getSetting(
			  category = "somecategory"
			, setting  = "asetting"
			, default  = "defaultResult"
		) );
	}

	function test09_getCategorySettings_shouldReturnAStructureOfAllSavedSettingsForAGivenCategory() {
		mockPresideObjectService.$( "selectData" )
			.$args( objectName="system_config", selectFields=[ "setting", "value" ], filter={ category="mycategory" } )
			.$results( QueryNew( 'setting,value', 'varchar,varchar', [ [ "setting1", "value1" ], [ "setting2", "value2" ], [ "setting3", "value3" ] ] ) );

		super.assertEquals( {
			  setting1 = "value1"
			, setting2 = "value2"
			, setting3 = "value3"
		}, _getConfigSvc().getCategorySettings( category="mycategory" ) );
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