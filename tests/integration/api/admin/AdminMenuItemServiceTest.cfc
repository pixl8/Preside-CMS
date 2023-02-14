component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "itemHasConfiguration( itemId )", function(){
			it( "should return true when item is found in item settings struct", function(){
				expect( _getService().itemHasConfiguration( "itemA" ) ).toBeTrue();
			} );
			it( "should return false when item is not found in item settings struct", function(){
				expect( _getService().itemHasConfiguration( "lsdkjf" ) ).toBeFalse();
			} );
		} );

		describe( "itemIsSeparator( itemId )", function(){
			it( "should return true when itemId is '-'", function(){
				expect( _getService().itemIsSeparator( "-" ) ).toBeTrue();
			} );
			it( "should return true when itemId is not '-'", function(){
				expect( _getService().itemIsSeparator( "aldkj" ) ).toBeFalse();
			} );
		} );

		describe( "itemIsLegacyViewImplementation( itemId, legacyViewBase )", function(){
			it( "should return false when item has a config entry", function(){
				var svc = _getService();
				var itemId = CreateUUId();
				var legacyViewBase = CreateUUId();

				svc.$( "itemHasConfiguration" ).$args( itemId ).$results( true );
				coldbox.$( "viewExists" ).$args( legacyViewBase & itemId ).$results( true );

				expect( svc.itemIsLegacyViewImplementation( itemId, legacyViewBase ) ).toBeFalse();
			} );
			it( "should return true when item has corresponding convention based view", function(){
				var svc = _getService();
				var itemId = CreateUUId();
				var legacyViewBase = CreateUUId();

				svc.$( "itemHasConfiguration" ).$args( itemId ).$results( false );
				coldbox.$( "viewExists" ).$args(  legacyViewBase & itemId  ).$results( true );

				expect( svc.itemIsLegacyViewImplementation( itemId, legacyViewBase ) ).toBeTrue();
			} );
			it( "should return false when item does not have corresponding convention based view", function(){
				var svc = _getService();
				var itemId = CreateUUId();
				var legacyViewBase = CreateUUId();

				svc.$( "itemHasConfiguration" ).$args( itemId ).$results( false );
				coldbox.$( "viewExists" ).$args(  legacyViewBase & itemId  ).$results( false );

				expect( svc.itemIsLegacyViewImplementation( itemId, legacyViewBase ) ).toBeFalse();
			} );
		} );

		describe( "itemHasHandlerAction( itemId, action )", function(){
			it( "should return true when item has corresponding convention based handler", function(){
				var svc = _getService();
				var itemId = CreateUUId();
				var action = CreateUUId();

				coldbox.$( "handlerExists" ).$args( "admin.layout.menuitem.#itemId#.#action#" ).$results( true );

				expect( svc.itemHasHandlerAction( itemId, action ) ).toBeTrue();
			} );
			it( "should return true when item does not have corresponding convention based handler", function(){
				var svc    = _getService();		
				
				var itemId = CreateUUId();
				var action = CreateUUId();

				coldbox.$( "handlerExists" ).$args( "admin.layout.menuitem.#itemId#.#action#" ).$results( false );

				expect( svc.itemHasHandlerAction( itemId, action ) ).toBeFalse();
			} );
		} );

		describe( "runItemHandlerAction( itemId, action, args )", function(){
			it( "should do nothing when the action does not exist", function(){
				var svc    = _getService();
				var itemId = CreateUUId();
				var action = CreateUUId();

				svc.$( "itemHasHandlerAction" ).$args( itemId, action ).$results( false );

				svc.runItemHandlerAction( itemId, action );

				expect( coldbox.$callLog().runEvent.len() ).toBe( 0 );

			} );

			it( "should use coldbox.runEvent() to run the convention based handler as passed", function(){
				var svc         = _getService();
				var itemId      = CreateUUId();
				var action      = CreateUUId();
				var args        = { test=CreateUUId() };
				var dummyResult = CreateUUId();

				svc.$( "itemHasHandlerAction" ).$args( itemId, action ).$results( true );
				coldbox.$( "runEvent" ).$args(
					  event          = "admin.layout.menuitem.#itemId#.#action#"
					, private        = true
					, prepostExempt  = true
					, eventArguments = { args=args }
				).$results( dummyResult );

				expect( svc.runItemHandlerAction( itemId, action, args ) ).toBe( dummyResult );

			} );

			it( "should return passed defaultResult if no value returned from handler", function(){
				var svc         = _getService();
				var itemId      = CreateUUId();
				var action      = CreateUUId();
				var args        = { test=CreateUUId() };
				var defaultResult = CreateUUId();

				svc.$( "itemHasHandlerAction" ).$args( itemId, action ).$results( true );
				coldbox.$( "runEvent" ).$args(
					  event          = "admin.layout.menuitem.#itemId#.#action#"
					, private        = true
					, prepostExempt  = true
					, eventArguments = { args=args }
				).$results( NullValue() );

				expect( svc.runItemHandlerAction( itemId, action, args, defaultResult ) ).toBe( defaultResult );
			} );

			it( "should return passed defaultResult if handler does not exist", function(){
				var svc    = _getService();
				var itemId = CreateUUId();
				var action = CreateUUId();
				var defaultResult = CreateUUId();

				svc.$( "itemHasHandlerAction" ).$args( itemId, action ).$results( false );

				expect( svc.runItemHandlerAction( itemId, action, {}, defaultResult ) ).toBe( defaultResult );
			} );
		} );

		describe( "getRawItemConfig( itemId, legacyViewBase )", function(){
			it( "should return a simple config when the item is a separator", function(){
				var svc = _getService();

				expect( svc.getRawItemConfig( "-", "blah" ) ).toBe( { separator=true } );
			} );

			it( "should return a simple config when the item is just a view implementation", function(){
				var svc = _getService();
				var itemId = CreateUUId();
				var legacyViewBase = CreateUUId();

				svc.$( "itemIsLegacyViewImplementation" ).$args( itemId, legacyViewBase ).$results( true );

				expect( svc.getRawItemConfig( itemId, legacyViewBase ) ).toBe( { view=legacyViewBase & itemId } );
			} );

			it( "should return any configuration specified in config.cfc for the item", function(){
				var svc = _getService();
				var itemId = "itemA";
				var legacyViewBase = CreateUUId();

				svc.$( "itemIsLegacyViewImplementation" ).$args( itemId, legacyViewBase ).$results( false );
				svc.$( "itemIsActive", false );

				var config = svc.getRawItemConfig( itemId, legacyViewBase );

				expect( config.thisIsATest ?: "noitisnot" ).toBe( "yesitis" );
			} );
		} );

		describe( "prepareItemForRequest( itemId, legacyViewBase )", function(){
			it( "should add dynamic elements to rawConfig from isActive, buildLink etc.", function(){
				var svc = _getService();
				var itemId = CreateUUId();
				var legacyViewBase = CreateUUId();
				var rawConfig = { test=true };

				svc.$( "itemIsLegacyViewImplementation" ).$args( itemId, legacyViewBase ).$results( false );
				svc.$( "itemIsActive", true );
				svc.$( "buildItemLink", "test" );
				svc.$( "getRawItemConfig" ).$args( itemId, legacyViewBase ).$results( rawConfig );
				svc.$( "runItemHandlerAction" ).$args( itemId, "prepare", rawConfig );

				var config = svc.prepareItemForRequest( itemId, legacyViewBase );

				expect( config.active ?: "noitisnot" ).toBe( true );
				expect( config.link ?: "noitisnot" ).toBe( "test" );
			} );
		} );

		describe( "itemIsActive( itemId, itemConfig )", function(){
			it( "should return true if item config has one or more active children", function(){
				var svc = _getService();
				var itemId = CreateUUId();
				var itemConfig = { subMenuItems=[ {active=false}, {active=true}, {active=false} ] };

				expect( svc.itemIsActive( itemId, itemConfig ) ).toBeTrue();
			} );

			it( "should return false if item config has one or more children none of which are active", function(){
				var svc = _getService();
				var itemId = CreateUUId();
				var itemConfig = { subMenuItems=[ {active=false}, {active=false}, {active=false} ] };

				expect( svc.itemIsActive( itemId, itemConfig ) ).toBeFalse();
			} );

			it( "should return true if item specifies a handler pattern and current handler matches it", function(){
				var svc = _getService();
				var itemId = CreateUUId();
				var itemConfig = { activeChecks={ handlerPatterns="^test\.blah\..*" } };

				requestContext.$( "getCurrentEvent", "test.blah.something" );

				expect( svc.itemIsActive( itemId, itemConfig ) ).toBeTrue();
			} );

			it( "should return false if item specifies a handler pattern and current handler does not match it", function(){
				var svc = _getService();
				var itemId = CreateUUId();
				var itemConfig = { activeChecks={ handlerPatterns="^test\.blah\..*" } };

				requestContext.$( "getCurrentEvent", "not.this.something" );

				expect( svc.itemIsActive( itemId, itemConfig ) ).toBeFalse();
			} );

			it( "should return true if item specifies handler patterns array and current handler matches any one", function(){
				var svc = _getService();
				var itemId = CreateUUId();
				var itemConfig = { activeChecks={ handlerPatterns=[ "$not\.this\.one", "^test\.blah\..*", "^orthisone" ] } };

				requestContext.$( "getCurrentEvent", "test.blah.something" );

				expect( svc.itemIsActive( itemId, itemConfig ) ).toBeTrue();
			} );

			it( "should return true if item specifies handler patterns array and current handler matches any one", function(){
				var svc = _getService();
				var itemId = CreateUUId();
				var itemConfig = { activeChecks={ handlerPatterns=[ "$not\.this\.one", "^test\.blah\..*", "^orthisone" ] } };

				requestContext.$( "getCurrentEvent", "not.this.something" );

				expect( svc.itemIsActive( itemId, itemConfig ) ).toBeFalse();
			} );

			it( "should return true if item specifies a datamanager object name and the current data manager object matches it", function(){
				var svc = _getService();
				var itemId = CreateUUId();
				var itemConfig = { activeChecks={ datamanagerObject="testObject" } };

				requestContext.$( "getCurrentEvent", "test.blah.something" );
				requestContext.$( "isDataManagerRequest", true );
				requestContext.$( "getCollection" ).$args( private=true ).$results( { objectName="testObject" } );

				expect( svc.itemIsActive( itemId, itemConfig ) ).toBeTrue();
			} );

			it( "should return false if item specifies a datamanager object name and the current data manager object matches it", function(){
				var svc = _getService();
				var itemId = CreateUUId();
				var itemConfig = { activeChecks={ datamanagerObject="testObject" } };

				requestContext.$( "getCurrentEvent", "test.blah.something" );
				requestContext.$( "isDataManagerRequest", true );
				requestContext.$( "getCollection" ).$args( private=true ).$results( { objectName="testObjectTest" } );

				expect( svc.itemIsActive( itemId, itemConfig ) ).toBeFalse();
			} );

			it( "should return true if item specifies a datamanager object name array and the current data manager object matches any one", function(){
				var svc = _getService();
				var itemId = CreateUUId();
				var itemConfig = { activeChecks={ datamanagerObject=[ "testObject", "another_object", "obj_three" ] } };

				requestContext.$( "getCurrentEvent", "test.blah.something" );
				requestContext.$( "isDataManagerRequest", true );
				requestContext.$( "getCollection" ).$args( private=true ).$results( { objectName="another_object" } );

				expect( svc.itemIsActive( itemId, itemConfig ) ).toBeTrue();
			} );

			it( "should return false if item specifies a datamanager object name array and the current data manager does not match any", function(){
				var svc = _getService();
				var itemId = CreateUUId();
				var itemConfig = { activeChecks={ datamanagerObject=[ "testObject", "another_object", "obj_three" ] } };

				requestContext.$( "getCurrentEvent", "test.blah.something" );
				requestContext.$( "isDataManagerRequest", true );
				requestContext.$( "getCollection" ).$args( private=true ).$results( { objectName="some_object" } );

				expect( svc.itemIsActive( itemId, itemConfig ) ).toBeFalse();
			} );

			it( "should return true if item's isActive handler returns true", function(){
				var svc = _getService();
				var itemId = CreateUUId();
				var itemConfig = { test="test" };

				requestContext.$( "getCurrentEvent", "test.blah.something" );
				svc.$( "runItemHandlerAction" ).$args( itemId=itemId, action="isActive", args=itemConfig, defaultResult=false ).$results( true );

				expect( svc.itemIsActive( itemId, itemConfig ) ).toBeTrue();
			} );

			it( "should return false otherwise", function(){
				var svc = _getService();
				var itemId = CreateUUId();
				var itemConfig = { test="test" };

				requestContext.$( "getCurrentEvent", "test.blah.something" );
				svc.$( "runItemHandlerAction" ).$args( itemId=itemId, action="isActive", args=itemConfig, defaultResult=false ).$results( false );

				expect( svc.itemIsActive( itemId, itemConfig ) ).toBeFalse();
			} );
		} );

		describe( "buildItemLink( itemId, itemConfig )", function(){
			it( "should use custom buildLink method of item handler when it exists", function(){
				var svc      = _getService();
				var itemId   = CreateUUId();
				var itemConfig = { test=true };
				var link     = "https://#CreateUUId()#.com";

				svc.$( "itemHasHandlerAction" ).$args( itemId, "buildLink" ).$results( true );
				svc.$( "runItemHandlerAction" ).$args( itemId=itemId, action="buildLink", args=itemConfig, defaultResult="" ).$results( link );

				expect( svc.buildItemLink( itemId, itemConfig ) ).toBe( link );
			} );

			it( "should use buildLinkArgs settings to pass to event.buildLink()", function(){
				var svc      = _getService();
				var itemId   = CreateUUId();
				var itemConfig = { test=true, buildLinkArgs={ objectName="test", recordId=CreateUUId() } };
				var link     = "https://#CreateUUId()#.com";

				svc.$( "itemHasHandlerAction" ).$args( itemId, "buildLink" ).$results( false );
				requestContext.$( "buildAdminLink" ).$args( argumentCollection=itemConfig.buildLinkArgs ).$results( link );

				expect( svc.buildItemLink( itemId, itemConfig ) ).toBe( link );
			} );

			it( "should return empty string otherwise", function(){
				var svc      = _getService();
				var itemId   = CreateUUId();
				var itemConfig = { test=true };

				svc.$( "itemHasHandlerAction" ).$args( itemId, "buildLink" ).$results( false );

				expect( svc.buildItemLink( itemId, itemConfig ) ).toBe( "" );
			} );
		} );

		describe( "itemShouldBeIncluded( itemId )", function(){
			it( "should return true when the item is a separator", function(){
				var svc = _getService();

				expect( svc.itemShouldBeIncluded( "-", "blah" ) ).toBeTrue();
			} );

			it( "should return true when the item is implemented only using the legacy view method", function(){
				var svc = _getService();
				var itemId  = CreateUUId();
				var legacyViewBase = CreateUUId();

				svc.$( "itemIsLegacyViewImplementation" ).$args( itemId, legacyViewBase ).$results( true );

				expect( svc.itemShouldBeIncluded( itemId, legacyViewBase ) ).toBeTrue();
			} );

			it( "should return false when the item's custom neverInclude action returns true", function(){
				var svc = _getService();
				var itemId = CreateUUId();
				var legacyViewBase = CreateUUId();

				svc.$( "itemHasConfiguration" ).$args( itemId ).$results( true );
				svc.$( "itemIsLegacyViewImplementation" ).$args( itemId, legacyViewBase ).$results( false );

				svc.$( "runItemHandlerAction" ).$args( itemId=itemId, action="neverInclude", defaultResult=false ).$results( true );

				expect( svc.itemShouldBeIncluded( itemId, legacyViewBase ) ).toBeFalse();
			} );

			it( "should return false when the item's custom includeForUser action returns false", function(){
				var svc = _getService();
				var itemId  = CreateUUId();
				var legacyViewBase = CreateUUId();

				svc.$( "itemHasConfiguration" ).$args( itemId ).$results( true );
				svc.$( "itemIsLegacyViewImplementation" ).$args( itemId, legacyViewBase ).$results( false );

				svc.$( "runItemHandlerAction" ).$args( itemId=itemId, action="neverInclude", defaultResult=false ).$results( false );
				svc.$( "runItemHandlerAction" ).$args( itemId=itemId, action="includeForUser", defaultResult=true ).$results( false );

				expect( svc.itemShouldBeIncluded( itemId, legacyViewBase ) ).toBeFalse();
			} );

			it( "should return false when the item's config specifies a disabled feature dependency", function(){
				var svc = _getService();
				var itemId  = CreateUUId();
				var config = { feature=CreateUUId() };
				var legacyViewBase = CreateUUId();

				svc.$( "itemHasConfiguration" ).$args( itemId ).$results( true );
				svc.$( "itemIsLegacyViewImplementation" ).$args( itemId, legacyViewBase ).$results( false );
				svc.$( "runItemHandlerAction" ).$args( itemId=itemId, action="neverInclude", defaultResult=false ).$results( false );
				svc.$( "runItemHandlerAction" ).$args( itemId=itemId, action="includeForUser", defaultResult=true ).$results( true );

				svc.$( "getRawItemConfig" ).$args( itemId, legacyViewBase ).$results( config );
				svc.$( "$isFeatureEnabled" ).$args( config.feature ).$results( false );

				expect( svc.itemShouldBeIncluded( itemId, legacyViewBase ) ).toBeFalse();
			} );

			it( "should return false when the item's config specifies a permission key that the current admin user does not have permission for", function(){
				var svc = _getService();
				var itemId  = CreateUUId();
				var config = { permissionKey=CreateUUId() };
				var legacyViewBase = CreateUUId();

				svc.$( "itemHasConfiguration" ).$args( itemId ).$results( true );
				svc.$( "itemIsLegacyViewImplementation" ).$args( itemId, legacyViewBase ).$results( false );
				svc.$( "runItemHandlerAction" ).$args( itemId=itemId, action="neverInclude", defaultResult=false ).$results( false );
				svc.$( "runItemHandlerAction" ).$args( itemId=itemId, action="includeForUser", defaultResult=true ).$results( true );

				svc.$( "getRawItemConfig" ).$args( itemId, legacyViewBase ).$results( config );
				svc.$( "$hasAdminPermission" ).$args( config.permissionKey ).$results( false );

				expect( svc.itemShouldBeIncluded( itemId, legacyViewBase ) ).toBeFalse();
			} );

			it( "should return true otherwise", function(){
				var svc            = _getService();
				var itemId         = CreateUUId();
				var config         = { permissionKey=CreateUUId(), feature=CreateUUId()  };
				var legacyViewBase = CreateUUId();

				svc.$( "itemHasConfiguration" ).$args( itemId ).$results( true );
				svc.$( "itemIsLegacyViewImplementation" ).$args( itemId, legacyViewBase ).$results( false );
				svc.$( "runItemHandlerAction" ).$args( itemId=itemId, action="neverInclude", defaultResult=false ).$results( false );
				svc.$( "runItemHandlerAction" ).$args( itemId=itemId, action="includeForUser", defaultResult=true ).$results( true );

				svc.$( "getRawItemConfig" ).$args( itemId, legacyViewBase ).$results( config );
				svc.$( "$hasAdminPermission" ).$args( config.permissionKey ).$results( true );
				svc.$( "$isFeatureEnabled" ).$args( config.feature ).$results( true );

				expect( svc.itemShouldBeIncluded( itemId, legacyViewBase ) ).toBeTrue();
			} );
		} );
	}

// private helpers
	private function _getService( struct itemSettings=_getDefaultItemSettings() ) {
		var svc = CreateMock( object=new preside.system.services.admin.AdminMenuItemService( itemSettings=arguments.itemSettings ) );

		coldbox = createStub();
		coldbox.$( "runEvent" );
		requestContext = createStub();
		requestContext.$( "getCollection", {} );

		svc.$( "$getColdbox", coldbox );
		svc.$( "$getRequestContext", requestContext );
		svc.$( "$isFeatureEnabled", true );
		svc.$( "$translateResource", "translated" );

		return svc;
	}

	private struct function _getDefaultItemSettings() {
		return {
			itemA = { title="test", linkArgs={ linkto="blah.test" }, thisIsATest="yesitis" }
		};
	}
}