component extends="tests.resources.HelperObjects.PresideBddTestCase"{

	function run(){

		describe( "listConfigCategories", function(){

			it( "should return empty array when no configuration categories defined", function(){
				expect( _getConfigSvc().listConfigCategories() ).toBe( [] );
			} );

			it( "should return an array of categories that have been auto discovered through the configured directories", function(){
				var expected     = [ "blog_settings", "client_settings", "mail_settings", "security_settings" ];
				var categories   = _getConfigSvc( testDirs ).listConfigCategories();
				var ids          = [];

				for( var cat in categories ){
					ArrayAppend( ids, cat.getid() );
				}

				ids.sort( "textnocase" );
				expect( ids ).toBe( expected );
			} );

		} );

		describe( "getConfigCategory", function(){
			it( "should return config category bean for given category", function(){
				var cat = _getConfigSvc( testDirs ).getConfigCategory( id="blog_settings" );

				expect( cat.getName()        ).toBe( "system-config.blog_settings:name"        );
				expect( cat.getDescription() ).toBe( "system-config.blog_settings:description" );
				expect( cat.getForm()        ).toBe( "system-config.blog_settings"             );
			} );

			it( "should throw informative error when category does not exist", function(){
				var errorThrown = false;

				try {
					_getConfigSvc( testDirs ).getConfigCategory( id="meh" );
				} catch( "SystemConfigurationService.category.notfound" e ){
					expect( e.message ).toBe( 'The configuration category [meh] could not be found. Configured categories are: ["blog_settings","client_settings","mail_settings","security_settings"]' );
					errorThrown = true;
				} catch ( any e ) {}

				expect( errorThrown ).toBeTrue();
			} );

		} );

		describe( "saveSetting", function(){
			it( "should insert a new db record when no existing record exists for the given config key", function(){
				var configService = _getConfigSvc( testDirs );

				mockDao.$( "selectData" )
					.$args( filter="category = :category and setting = :setting and site is null", filterParams={ category="mycategory", setting="mysetting" }, selectFields=["id"] )
					.$results( QueryNew('id') );

				mockDao.$( "insertData", CreateUUId() );

				configService.saveSetting(
					  category = "mycategory"
					, setting  = "mysetting"
					, value    = "this is the value of my setting"
				);

				var log = mockDao.$callLog().insertData;

				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( { data = { category="mycategory", setting="mysetting", value="this is the value of my setting", site="" } } );
			} );

			it( "should update existing db record when record already exists in db", function(){
				var configService = _getConfigSvc( testDirs );

				mockDao.$( "selectData" )
					.$args( filter="category = :category and setting = :setting and site is null", filterParams={ category="mycategory", setting="mysetting" }, selectFields=["id"] )
					.$results( QueryNew('id', "varchar", ["someid"] ) );

				mockDao.$( "insertData", CreateUUId() );
				mockDao.$( "updateData", 1 );

				configService.saveSetting(
					  category = "mycategory"
					, setting  = "mysetting"
					, value    = "this is the value of my setting"
				);

				var log = mockDao.$callLog().insertData;
				expect( log.len() ).toBe( 0 );

				log = mockDao.$callLog().updateData;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( { data = {  value="this is the value of my setting" }, id = "someid" } );
			} );

			it( "should insert a new db record with site ID when site id passed", function(){
				var configService = _getConfigSvc( testDirs );
				var siteId        = CreateUUId();

				mockDao.$( "selectData" )
					.$args( filter="category = :category and setting = :setting and site = :site", filterParams={ category="mycategory", setting="mysetting", site=siteId }, selectFields=["id"] )
					.$results( QueryNew('id') );

				mockDao.$( "insertData", CreateUUId() );

				configService.saveSetting(
					  category = "mycategory"
					, setting  = "mysetting"
					, value    = "this is the value of my setting"
					, siteId   = siteId
				);

				var log = mockDao.$callLog().insertData;

				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( { data = { category="mycategory", setting="mysetting", value="this is the value of my setting", site=siteId } } );
			} );

			it( "should clear related caches", function(){
				var configService = _getConfigSvc( testDirs );
				var siteId        = CreateUUId();

				mockDao.$( "selectData" )
					.$args( filter="category = :category and setting = :setting and site = :site", filterParams={ category="mycategory", setting="mysetting", site=siteId }, selectFields=["id"] )
					.$results( QueryNew('id') );

				mockDao.$( "insertData", CreateUUId() );


				configService.saveSetting(
					  category = "mycategory"
					, setting  = "mysetting"
					, value    = "this is the value of my setting"
					, siteId   = siteId
				);

				var log = mockCache.$callLog().clearByKeySnippet;

				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( {
					  keySnippet = "^setting\.mycategory\."
					, regex      = true
					, async      = false
				} );
			} );

		} );

		describe( "getSetting", function(){

			it( "should return values as saved in the database for given category and setting that are saved against the currently active site", function(){
				var configService = _getConfigSvc( testDirs );

				mockDao.$( "selectData" )
					.$args( filter={ category="somecategory", setting="asetting", site=activeSite }, selectFields=["value"] )
					.$results( QueryNew('value', "varchar", ["this is the correct result"] ) );

				expect( configService.getSetting(
					  category = "somecategory"
					, setting  = "asetting"
				) ).toBe( "this is the correct result" );
			} );

			it( "should return global default values as saved in the database for given category and setting when no setting found for active site", function(){
				var configService = _getConfigSvc( testDirs );

				mockDao.$( "selectData" )
					.$args( filter={ category="somecategory", setting="asetting", site=activeSite }, selectFields=["value"] )
					.$results( QueryNew( 'value' ) );

				mockDao.$( "selectData" )
					.$args( filter="category = :category and setting = :setting and site is null", filterParams={ category="somecategory", setting="asetting" }, selectFields=["value"] )
					.$results( QueryNew('value', "varchar", ["this is the correct result"] ) );

				expect( configService.getSetting(
					  category = "somecategory"
					, setting  = "asetting"
				) ).toBe( "this is the correct result" );
			} );

			it( "should return passed default when no record exists for either site or global default", function(){
				var configService = _getConfigSvc( testDirs );

				mockDao.$( "selectData" )
					.$args( filter={ category="somecategory", setting="asetting", site=activeSite }, selectFields=["value"] )
					.$results( QueryNew('value') );

				mockDao.$( "selectData" )
					.$args( filter="category = :category and setting = :setting and site is null", filterParams={ category="somecategory", setting="asetting" }, selectFields=["value"] )
					.$results( QueryNew('value') );

				expect( configService.getSetting(
					  category = "somecategory"
					, setting  = "asetting"
					, default  = "defaultResult"
				) ).toBe( "defaultResult");
			} );

			it( "should fall back to injected setting when setting does not exist", function(){
				var configService = _getConfigSvc( injectedConfig = { "injectedCat.injectedSetting" = "test value for injected settings" } );

				mockDao.$( "selectData" )
					.$args( filter={ category="injectedCat", setting="injectedSetting", site=activeSite }, selectFields=["value"] )
					.$results( QueryNew('value') );

				mockDao.$( "selectData" )
					.$args( filter="category = :category and setting = :setting and site is null", filterParams={ category="injectedCat", setting="injectedSetting" }, selectFields=["value"] )
					.$results( QueryNew('value') );

				expect( configService.getSetting( category="injectedCat", setting="injectedSetting" ) ).toBe( "test value for injected settings" );
			} );

		} );

		describe( "getCategorySettings", function(){

			it( "should return a struct of all saved setting for a given category for the currently active site merged with those from global settings", function(){
				var configService = _getConfigSvc();

				mockDao.$( "selectData" )
					.$args( selectFields=[ "setting", "value" ], filter={ category="mycategory", site=activeSite } )
					.$results( QueryNew( 'setting,value', 'varchar,varchar', [ [ "setting1", "value1" ], [ "setting2", "value2" ] ] ) );

				mockDao.$( "selectData" )
					.$args( selectFields=[ "setting", "value" ], filter="category = :category and site is null", filterParams={ category="mycategory" } )
					.$results( QueryNew( 'setting,value', 'varchar,varchar', [ [ "setting1", "value1global" ], [ "setting2", "value2global" ], [ "setting3", "value3global" ] ] ) );

				expect( configService.getCategorySettings( category="mycategory" ) ).toBe( {
					  setting1 = "value1"
					, setting2 = "value2"
					, setting3 = "value3global"
				} );
			} );

			it( "should return a structure of all saved settings mixed in with injected settings", function(){
				var configService = _getConfigSvc( injectedConfig = {
					  "injectedCat.injectedSetting" = "test value for injected settings"
					, "mycategory.setting1"         = "valuex"
					, "mycategory.setting4"         = "another value"
				} );

				mockDao.$( "selectData" )
					.$args( selectFields=[ "setting", "value" ], filter={ category="mycategory", site=activeSite } )
					.$results( QueryNew( 'setting,value', 'varchar,varchar', [ [ "setting1", "value1" ], [ "setting3", "value3" ] ] ) );

				mockDao.$( "selectData" )
					.$args( selectFields=[ "setting", "value" ], filter="category = :category and site is null", filterParams={ category="mycategory" } )
					.$results( QueryNew( 'setting,value', 'varchar,varchar', [ [ "setting1", "value1global" ], [ "setting2", "value2global" ], [ "setting3", "value3global" ] ] ) );


				expect( configService.getCategorySettings( category="mycategory" ) ).toBe( {
					  setting1 = "value1"
					, setting2 = "value2global"
					, setting3 = "value3"
					, setting4 = "another value"
				} );
			} );

			it( "should not mixin global or injected settings when explicitly asked not to do so with the includeDefaults argument", function(){
				var configService = _getConfigSvc( injectedConfig = {
					  "injectedCat.injectedSetting" = "test value for injected settings"
					, "mycategory.setting1"         = "valuex"
					, "mycategory.setting4"         = "another value"
				} );

				mockDao.$( "selectData" )
					.$args( selectFields=[ "setting", "value" ], filter={ category="mycategory", site=activeSite } )
					.$results( QueryNew( 'setting,value', 'varchar,varchar', [ [ "setting1", "value1" ], [ "setting3", "value3" ] ] ) );

				mockDao.$( "selectData" )
					.$args( selectFields=[ "setting", "value" ], filter="category = :category and site is null", filterParams={ category="mycategory" } )
					.$results( QueryNew( 'setting,value', 'varchar,varchar', [ [ "setting1", "value1global" ], [ "setting2", "value2global" ], [ "setting3", "value3global" ] ] ) );


				expect( configService.getCategorySettings( category="mycategory", includeDefaults=false ) ).toBe( {
					  setting1 = "value1"
					, setting3 = "value3"
				} );
			} );

			it( "should only retreive global and injected when explicitly asked to do so with the globalDefaultsOnly argument", function(){
				var configService = _getConfigSvc( injectedConfig = {
					  "injectedCat.injectedSetting" = "test value for injected settings"
					, "mycategory.setting1"         = "valuex"
					, "mycategory.setting4"         = "another value"
				} );

				mockDao.$( "selectData" )
					.$args( selectFields=[ "setting", "value" ], filter={ category="mycategory", site=activeSite } )
					.$results( QueryNew( 'setting,value', 'varchar,varchar', [ [ "setting1", "value1" ], [ "setting3", "value3" ], [ "setting5", "value5" ] ] ) );

				mockDao.$( "selectData" )
					.$args( selectFields=[ "setting", "value" ], filter="category = :category and site is null", filterParams={ category="mycategory" } )
					.$results( QueryNew( 'setting,value', 'varchar,varchar', [ [ "setting1", "value1global" ], [ "setting2", "value2global" ], [ "setting3", "value3global" ] ] ) );


				expect( configService.getCategorySettings( category="mycategory", globalDefaultsOnly=true ) ).toBe( {
					  setting1 = "value1global"
					, setting2 = "value2global"
					, setting3 = "value3global"
					, setting4 = "another value"
				} );
			} );

		} );
	}

// PRIVATE HELPERS
	private any function _getConfigSvc( array autoDiscoverDirectories=[], struct injectedConfig={} ) ouput=false {
		mockDao          = createEmptyMock( object=_getPresideObjectService().getObject( "system_config" ) );
		testDirs         = [ "/tests/resources/systemConfiguration/dir1", "/tests/resources/systemConfiguration/dir2", "/tests/resources/systemConfiguration/dir3" ];
		mockFormsService = createEmptyMock( "preside.system.services.forms.FormsService" );
		mockSiteService  = createEmptyMock( "preside.system.services.siteTree.SiteService" );
		mockCache        = createStub();

		mockFormsService.$( "formExists" ).$args( formName="system-config.disabled_feature_settings", checkSiteTemplates=false ).$results( false );
		mockFormsService.$( "formExists", true );
		mockFormsService.$( "createForm", CreateUUId() );

		activeSite = CreateUUId();
		mockSiteService.$( "getActiveSiteId", activeSite );

		mockCache.$( "get" );
		mockCache.$( "set" );
		mockCache.$( "clearByKeySnippet" );

		var svc = CreateMock( object=new preside.system.services.configuration.SystemConfigurationService(
			  dao                     = mockDao
			, autoDiscoverDirectories = arguments.autoDiscoverDirectories
			, env                     = arguments.injectedConfig
			, formsService            = mockFormsService
			, siteService             = mockSiteService
			, settingsCache           = mockCache
		) );

		svc.$( "$announceInterception" );

		return svc;
	}

}