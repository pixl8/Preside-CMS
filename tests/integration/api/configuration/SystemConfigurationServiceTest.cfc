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

		describe( "getConfigCategoryTenancy", function(){
			it( "should return 'site' for default configurations", function(){
				var tenant = _getConfigSvc( testDirs ).getConfigCategoryTenancy( id="blog_settings" );
				expect( tenant ).toBe( "site" );
			} );
			it( "should return an empty string for categories with noTenancy=true specified in their form", function(){
				var tenant = _getConfigSvc( testDirs ).getConfigCategoryTenancy( id="security_settings" );
				expect( tenant ).toBe( "" );
			} );
			it( "should return a specified custom tenant when tenancy='x' is set on the form", function(){
				var tenant = _getConfigSvc( testDirs ).getConfigCategoryTenancy( id="mail_settings" );
				expect( tenant ).toBe( "custom" );
			} );
		} );

		describe( "saveSetting", function(){
			it( "should insert a new db record when no existing record exists for the given config key", function(){
				var configService = _getConfigSvc( testDirs );
				var category = "mycategory";

				configService.$( "getConfigCategoryTenancy" ).$args( category ).$results( "site" );

				mockDao.$( "updateData" )
					.$args( filter="category = :category and setting = :setting and site is null and tenant_id is null", filterParams={ category=category, setting="mysetting" }, data={ value="this is the value of my setting" } )
					.$results( 0 );

				mockDao.$( "insertData", CreateUUId() );

				configService.saveSetting(
					  category = category
					, setting  = "mysetting"
					, value    = "this is the value of my setting"
				);

				var log = mockDao.$callLog().insertData;

				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( [ { category=category, setting="mysetting", value="this is the value of my setting", site="", tenant_id="" } ] );
			} );

			it( "should update existing db record when record already exists in db", function(){
				var configService = _getConfigSvc( testDirs );
				var category = "mycategory";

				configService.$( "getConfigCategoryTenancy" ).$args( category ).$results( "site" );


				mockDao.$( "updateData" )
					.$args( filter="category = :category and setting = :setting and site is null and tenant_id is null", filterParams={ category=category, setting="mysetting" }, data={ value="this is the value of my setting" } )
					.$results( 1 );

				mockDao.$( "insertData", CreateUUId() );

				configService.saveSetting(
					  category = category
					, setting  = "mysetting"
					, value    = "this is the value of my setting"
				);

				var log = mockDao.$callLog().insertData;
				expect( log.len() ).toBe( 0 );

				log = mockDao.$callLog().updateData;
				expect( log.len() ).toBe( 1 );
			} );

			it( "should insert a new db record with site ID when site id passed", function(){
				var configService = _getConfigSvc( testDirs );
				var siteId        = CreateUUId();
				var category      = "mycategory";

				configService.$( "getConfigCategoryTenancy" ).$args( category ).$results( "site" );

				mockDao.$( "updateData" )
					.$args( filter="category = :category and setting = :setting and site = :site", filterParams={ category=category, setting="mysetting", site=siteId }, data={ value="this is the value of my setting" } )
					.$results( 0 );

				mockDao.$( "insertData", CreateUUId() );

				configService.saveSetting(
					  category = category
					, setting  = "mysetting"
					, value    = "this is the value of my setting"
					, tenantId = siteId
				);

				var log = mockDao.$callLog().insertData;

				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( [ { category=category, setting="mysetting", value="this is the value of my setting", site=siteId, tenant_id="" } ] );
			} );

			it( "should clear related caches", function(){
				var configService = _getConfigSvc( testDirs );
				var siteId        = CreateUUId();
				var category      = "mycategory";

				configService.$( "getConfigCategoryTenancy" ).$args( category ).$results( "site" );

				mockDao.$( "updateData" )
					.$args( filter="category = :category and setting = :setting and site = :site", filterParams={ category=category, setting="mysetting", site=siteId }, data={ value="this is the value of my setting" } )
					.$results( 1 );

				mockDao.$( "insertData", CreateUUId() );


				configService.saveSetting(
					  category = category
					, setting  = "mysetting"
					, value    = "this is the value of my setting"
					, tenantId = siteId
				);

				var log = mockCache.$callLog().clearByKeySnippet;

				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( {
					  keySnippet = "^setting\.#category#\."
					, regex      = true
					, async      = false
				} );
			} );

			it( "should insert a new db record with temamt ID when category uses custom tenancy", function(){
				var configService  = _getConfigSvc( testDirs );
				var customTenantId = CreateUUId();
				var category       = "mycategory";

				configService.$( "getConfigCategoryTenancy" ).$args( category ).$results( "custom" );
				mockTenancyService.$( "getTenantId" ).$args( "custom" ).$results( customTenantId );

				mockDao.$( "updateData" )
					.$args( filter="category = :category and setting = :setting and tenant_id = :tenant_id", filterParams={ category=category, setting="mysetting", tenant_id=customTenantId }, data={ value="this is the value of my setting" } )
					.$results( 0 );

				mockDao.$( "insertData", CreateUUId() );

				configService.saveSetting(
					  category = category
					, setting  = "mysetting"
					, value    = "this is the value of my setting"
					, tenantId = customTenantId
				);

				var log = mockDao.$callLog().insertData;

				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( [ { category=category, setting="mysetting", value="this is the value of my setting", site="", tenant_id=customTenantId } ] );
			} );

		} );

		describe( "getSetting", function(){

			it( "should return values as saved in the database for given category and setting that are saved against the currently active site", function(){
				var configService = _getConfigSvc( testDirs );
				configService.$( "getConfigCategoryTenancy" ).$args( "somecategory" ).$results( "site" );

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

				configService.$( "getConfigCategoryTenancy" ).$args( "somecategory" ).$results( "site" );

				mockDao.$( "selectData" )
					.$args( filter={ category="somecategory", setting="asetting", site=activeSite }, selectFields=["value"] )
					.$results( QueryNew( 'value' ) );

				mockDao.$( "selectData" )
					.$args( filter="category = :category and setting = :setting and site is null and tenant_id is null", filterParams={ category="somecategory", setting="asetting" }, selectFields=["value"] )
					.$results( QueryNew('value', "varchar", ["this is the correct result"] ) );

				expect( configService.getSetting(
					  category = "somecategory"
					, setting  = "asetting"
				) ).toBe( "this is the correct result" );
			} );

			it( "should return passed default when no record exists for either site or global default", function(){
				var configService = _getConfigSvc( testDirs );

				configService.$( "getConfigCategoryTenancy" ).$args( "somecategory" ).$results( "site" );

				mockDao.$( "selectData" )
					.$args( filter={ category="somecategory", setting="asetting", site=activeSite }, selectFields=["value"] )
					.$results( QueryNew('value') );

				mockDao.$( "selectData" )
					.$args( filter="category = :category and setting = :setting and site is null and tenant_id is null", filterParams={ category="somecategory", setting="asetting" }, selectFields=["value"] )
					.$results( QueryNew('value') );

				expect( configService.getSetting(
					  category = "somecategory"
					, setting  = "asetting"
					, default  = "defaultResult"
				) ).toBe( "defaultResult");
			} );

			it( "should fall back to injected setting when setting does not exist", function(){
				var configService = _getConfigSvc( injectedConfig = { "injectedCat.injectedSetting" = "test value for injected settings" } );
				configService.$( "getConfigCategoryTenancy" ).$args( "injectedCat" ).$results( "site" );

				mockDao.$( "selectData" )
					.$args( filter={ category="injectedCat", setting="injectedSetting", site=activeSite }, selectFields=["value"] )
					.$results( QueryNew('value') );

				mockDao.$( "selectData" )
					.$args( filter="category = :category and setting = :setting and site is null and tenant_id is null", filterParams={ category="injectedCat", setting="injectedSetting" }, selectFields=["value"] )
					.$results( QueryNew('value') );

				expect( configService.getSetting( category="injectedCat", setting="injectedSetting" ) ).toBe( "test value for injected settings" );
			} );

			it( "should filter on tenant_id when category has custom tenancy", function(){
				var configService  = _getConfigSvc( testDirs );
				var customTenantId = CreateUUId();

				configService.$( "getConfigCategoryTenancy" ).$args( "somecategory" ).$results( "custom" );
				mockTenancyService.$( "getTenantId" ).$args( "custom" ).$results( customTenantId );

				mockDao.$( "selectData" )
					.$args( filter={ category="somecategory", setting="asetting", tenant_id=customTenantId }, selectFields=["value"] )
					.$results( QueryNew('value', "varchar", ["this is the correct result"] ) );

				expect( configService.getSetting(
					  category = "somecategory"
					, setting  = "asetting"
				) ).toBe( "this is the correct result" );
			} );

		} );

		describe( "getCategorySettings", function(){

			it( "should return a struct of all saved setting for a given category for the currently active site merged with those from global settings", function(){
				var configService = _getConfigSvc();
				var category      = "mycategory";

				configService.$( "getConfigCategoryTenancy" ).$args( category ).$results( "site" );

				mockDao.$( "selectData" )
					.$args( selectFields=[ "setting", "value" ], filter={ category=category, site=activeSite } )
					.$results( QueryNew( 'setting,value', 'varchar,varchar', [ [ "setting1", "value1" ], [ "setting2", "value2" ] ] ) );

				mockDao.$( "selectData" )
					.$args( selectFields=[ "setting", "value" ], filter="category = :category and site is null and tenant_id is null", filterParams={ category=category } )
					.$results( QueryNew( 'setting,value', 'varchar,varchar', [ [ "setting1", "value1global" ], [ "setting2", "value2global" ], [ "setting3", "value3global" ] ] ) );

				expect( configService.getCategorySettings( category=category ) ).toBe( {
					  setting1 = "value1"
					, setting2 = "value2"
					, setting3 = "value3global"
				} );
			} );

			it( "should return a structure of all saved settings mixed in with injected settings", function(){
				var category      = "mycategory";
				var configService = _getConfigSvc( injectedConfig = {
					  "injectedCat.injectedSetting" = "test value for injected settings"
					, "#category#.setting1"         = "valuex"
					, "#category#.setting4"         = "another value"
				} );

				configService.$( "getConfigCategoryTenancy" ).$args( category ).$results( "site" );

				mockDao.$( "selectData" )
					.$args( selectFields=[ "setting", "value" ], filter={ category=category, site=activeSite } )
					.$results( QueryNew( 'setting,value', 'varchar,varchar', [ [ "setting1", "value1" ], [ "setting3", "value3" ] ] ) );

				mockDao.$( "selectData" )
					.$args( selectFields=[ "setting", "value" ], filter="category = :category and site is null and tenant_id is null", filterParams={ category=category } )
					.$results( QueryNew( 'setting,value', 'varchar,varchar', [ [ "setting1", "value1global" ], [ "setting2", "value2global" ], [ "setting3", "value3global" ] ] ) );


				expect( configService.getCategorySettings( category=category ) ).toBe( {
					  setting1 = "value1"
					, setting2 = "value2global"
					, setting3 = "value3"
					, setting4 = "another value"
				} );
			} );

			it( "should not mixin global or injected settings when explicitly asked not to do so with the includeDefaults argument", function(){
				var category      = "mycategory";
				var configService = _getConfigSvc( injectedConfig = {
					  "injectedCat.injectedSetting" = "test value for injected settings"
					, "#category#.setting1"         = "valuex"
					, "#category#.setting4"         = "another value"
				} );

				configService.$( "getConfigCategoryTenancy" ).$args( category ).$results( "site" );

				mockDao.$( "selectData" )
					.$args( selectFields=[ "setting", "value" ], filter={ category=category, site=activeSite } )
					.$results( QueryNew( 'setting,value', 'varchar,varchar', [ [ "setting1", "value1" ], [ "setting3", "value3" ] ] ) );

				mockDao.$( "selectData" )
					.$args( selectFields=[ "setting", "value" ], filter="category = :category and site is null and tenant_id is null", filterParams={ category=category } )
					.$results( QueryNew( 'setting,value', 'varchar,varchar', [ [ "setting1", "value1global" ], [ "setting2", "value2global" ], [ "setting3", "value3global" ] ] ) );


				expect( configService.getCategorySettings( category=category, includeDefaults=false ) ).toBe( {
					  setting1 = "value1"
					, setting3 = "value3"
				} );
			} );

			it( "should only retreive global and injected when explicitly asked to do so with the globalDefaultsOnly argument", function(){
				var category      = "mycategory";
				var configService = _getConfigSvc( injectedConfig = {
					  "injectedCat.injectedSetting" = "test value for injected settings"
					, "#category#.setting1"         = "valuex"
					, "#category#.setting4"         = "another value"
				} );

				configService.$( "getConfigCategoryTenancy" ).$args( category ).$results( "site" );
				mockDao.$( "selectData" )
					.$args( selectFields=[ "setting", "value" ], filter={ category=category, site=activeSite } )
					.$results( QueryNew( 'setting,value', 'varchar,varchar', [ [ "setting1", "value1" ], [ "setting3", "value3" ], [ "setting5", "value5" ] ] ) );

				mockDao.$( "selectData" )
					.$args( selectFields=[ "setting", "value" ], filter="category = :category and site is null and tenant_id is null", filterParams={ category=category } )
					.$results( QueryNew( 'setting,value', 'varchar,varchar', [ [ "setting1", "value1global" ], [ "setting2", "value2global" ], [ "setting3", "value3global" ] ] ) );


				expect( configService.getCategorySettings( category=category, globalDefaultsOnly=true ) ).toBe( {
					  setting1 = "value1global"
					, setting2 = "value2global"
					, setting3 = "value3global"
					, setting4 = "another value"
				} );
			} );

			it( "should filter on tenant_id when using a category with custom tenancy", function(){
				var category      = "mycategory";
				var configService = _getConfigSvc();
				var customTenantId = CreateUUId();

				configService.$( "getConfigCategoryTenancy" ).$args( category ).$results( "custom" );
				mockTenancyService.$( "getTenantId" ).$args( "custom" ).$results( customTenantId );
				mockDao.$( "selectData" )
					.$args( selectFields=[ "setting", "value" ], filter={ category=category, tenant_id=customTenantId } )
					.$results( QueryNew( 'setting,value', 'varchar,varchar', [
						  [ "setting1", "value1" ]
						, [ "setting3", "value3" ]
						, [ "setting5", "value5" ]
					] ) );

				mockDao.$( "selectData" )
					.$args( selectFields=[ "setting", "value" ], filter="category = :category and site is null and tenant_id is null", filterParams={ category=category } )
					.$results( QueryNew( 'setting,value', 'varchar,varchar' ) );


				expect( configService.getCategorySettings( category=category ) ).toBe( {
					  setting1 = "value1"
					, setting3 = "value3"
					, setting5 = "value5"
				} );
			} );

		} );
	}

// PRIVATE HELPERS
	private any function _getConfigSvc( array autoDiscoverDirectories=[], struct injectedConfig={} ) ouput=false {
		mockDao            = createEmptyMock( object=_getPresideObjectService().getObject( "system_config" ) );
		testDirs           = [ "/tests/resources/systemConfiguration/dir1", "/tests/resources/systemConfiguration/dir2", "/tests/resources/systemConfiguration/dir3" ];
		mockFormsService   = createEmptyMock( "preside.system.services.forms.FormsService" );
		mockTenancyService = createEmptyMock( "preside.system.services.tenancy.TenancyService" );
		mockSiteService    = createEmptyMock( "preside.system.services.siteTree.SiteService" );
		mockCache          = createStub();
		helpers            = createStub();

		mockFormsService.$( "formExists" ).$args( formName="system-config.disabled_feature_settings", checkSiteTemplates=false ).$results( false );
		mockFormsService.$( "formExists", true );
		mockFormsService.$( "createForm", CreateUUId() );
		mockFormsService.$( "getForm" ).$args( "system-config.security_settings" ).$results( { notenancy=true } );
		mockFormsService.$( "getForm" ).$args( "system-config.mail_settings" ).$results( { tenancy="custom" } );
		mockFormsService.$( "getForm", {} );


		activeSite = CreateUUId();
		mockSiteService.$( "getActiveSiteId", activeSite );
		mockTenancyService.$( "getTenantId" ).$args( "site" ).$results( activeSite );

		mockCache.$( "get" );
		mockCache.$( "set" );
		mockCache.$( "clearByKeySnippet" );

		var svc = CreateMock( object=new preside.system.services.configuration.SystemConfigurationService(
			  dao                     = mockDao
			, autoDiscoverDirectories = arguments.autoDiscoverDirectories
			, env                     = arguments.injectedConfig
			, formsService            = mockFormsService
			, siteService             = mockSiteService
			, tenancyService          = mockTenancyService
			, settingsCache           = mockCache
		) );

		svc.$( "$announceInterception" );
		svc.$property( propertyName="$helpers", mock=helpers );
		helpers.$( method="isTrue", callback=function( val ){
			return IsBoolean( arguments.val ?: "" ) && arguments.val;
		} );

		return svc;
	}

}