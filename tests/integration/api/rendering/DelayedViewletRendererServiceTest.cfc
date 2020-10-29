component extends="tests.resources.HelperObjects.PresideBddTestCase"{

	function run(){
		describe( "renderDelayedViewlets()", function(){
			it( "should recursively replace delayed viewlet markup with dynamically rendered versions of the viewlet until there are no more viewlet markup tags left in the given content", function(){
				var service    = _getService();
				var complexArg = { test="this" };
				var dvs        = [
					  "<!--dv:test.viewlet( arg1=#ToBase64( 'true' )#, arg2=#ToBase64( 'test' )#, arg3=#ToBase64( SerializeJson( complexArg ) )# )(private=true,prePostExempt=false)-->"
					, "<!--dv:another.test.viewlet(arg3=#ToBase64( 'false' )#)(private=true,prePostExempt=true)-->"
					, "<!--dv:nested.viewlet()(private=false,prePostExempt=false)-->"
				];
				var replacements = {
					  "#dvs[1]#" = CreateUUId()
					, "#dvs[2]#" = "Test #dvs[3]#"
					, "#dvs[3]#" = CreateUUId()
				};
				var content = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
#dvs[1]# exercitation ullamco laboris nisi ut aliquip ex ea commodo
consequat. Duis aute irure dolor in reprehenderit in #dvs[1]# voluptate velit esse
cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non
proident, sunt in #dvs[2]# culpa qui officia deserunt mollit anim id est laborum.";
				var expected = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
#replacements[ dvs[1] ]#==RICHRENDERED exercitation ullamco laboris nisi ut aliquip ex ea commodo
consequat. Duis aute irure dolor in reprehenderit in #replacements[ dvs[1] ]#==RICHRENDERED voluptate velit esse
cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non
proident, sunt in Test #replacements[ dvs[3] ]#==RICHRENDERED==RICHRENDERED culpa qui officia deserunt mollit anim id est laborum.";

				mockColdbox.$( "renderViewlet" ).$args(
					  event         = "test.viewlet"
					, args          = { arg1=true, arg2='test', arg3=complexArg }
					, private       = true
					, prepostExempt = false
					, delayed       = false
				).$results( replacements[ dvs[1] ] );
				mockColdbox.$( "renderViewlet" ).$args(
					  event         = "another.test.viewlet"
					, args          = { arg3=false }
					, private       = true
					, prepostExempt = true
					, delayed       = false
				).$results( replacements[ dvs[2] ] );
				mockColdbox.$( "renderViewlet" ).$args(
					  event         = "nested.viewlet"
					, args          = {}
					, private       = false
					, prepostExempt = false
					, delayed       = false
				).$results( replacements[ dvs[3] ] );

				for( var replacementKey in replacements ) {
					mockContentRenderer.$( "render" ).$args( renderer="richeditor", data=replacements[ replacementKey ] ).$results( replacements[ replacementKey ] & "==RICHRENDERED" );
				}


				expect( service.renderDelayedViewlets( content ) ).toBe( expected );
			} );
		} );

		describe( "renderDelayedViewletTag()", function(){
			it( "should return an html comment string with urlencoded and json serialized args", function(){
				var service  = _getService();
				var event    = "test.event.viewlet";
				var args     = StructNew( 'linked' );
				var expected = "";

				args.aBool       = true
				args.aString     = "test"
				args.aNumber     = 345
				args.aComplexOne = { fubar=true, test={ stuff=CreateUUId() } }

				expected = "<!--dv:#event#(aBool=#ToBase64( 'true' )#,aString=#ToBase64( 'test' )#,aNumber=#ToBase64( '345' )#,aComplexOne=#ToBase64( SerializeJson( args.aComplexOne ) )#)(private=true,prepostexempt=false)-->";

				expect( service.renderDelayedViewletTag(
					  event         = event
					, args          = args
					, private       = true
					, prepostExempt = false
				) ).toBe( expected );
			} );
		} );

		describe( "isViewletDelayedByDefault()", function(){
			it( "should return false when viewlet does not have a handler", function(){
				var service = _getService();
				var viewlet = "test.this.viewlet";

				mockColdbox.$( "handlerExists" ).$args( viewlet ).$results( false );
				mockColdbox.$( "handlerExists" ).$args( viewlet & ".index" ).$results( false );

				expect( service.isViewletDelayedByDefault( viewlet ) ).toBe( false );
			} );

			it( "should return false when viewlet has a handler that does not set any 'cacheable' attribute", function(){
				var service           = _getService();
				var viewlet           = "test.this.viewlet";
				var handlerMethodMeta = { name="viewlet", private=true };

				mockColdbox.$( "handlerExists" ).$args( viewlet ).$results( true );
				service.$( "_getHandlerMethodMeta" ).$args( viewlet ).$results( handlerMethodMeta );

				expect( service.isViewletDelayedByDefault( viewlet ) ).toBe( false );
			} );

			it( "should return true when viewlet has a hander that sets a 'cacheable' attribute that is set to false", function(){
				var service           = _getService();
				var viewlet           = "test.this.viewlet";
				var handlerMethodMeta = { name="viewlet", private=true, cacheable=false };

				mockColdbox.$( "handlerExists" ).$args( viewlet ).$results( true );
				service.$( "_getHandlerMethodMeta" ).$args( viewlet ).$results( handlerMethodMeta );

				expect( service.isViewletDelayedByDefault( viewlet ) ).toBe( true );
			} );

			it( "should return true when _default_ is passed as true and viewlet does not specify any 'cacheable' instruction", function(){
				var service           = _getService();
				var viewlet           = "test.this.viewlet";
				var handlerMethodMeta = { name="viewlet", private=true };

				mockColdbox.$( "handlerExists" ).$args( viewlet ).$results( true );
				service.$( "_getHandlerMethodMeta" ).$args( viewlet ).$results( handlerMethodMeta );

				expect( service.isViewletDelayedByDefault( viewlet, true ) ).toBe( true );
			} );

			it( "should return false when the fullPageCaching feature is disabled", function(){
				var service           = _getService();
				var viewlet           = "test.this.viewlet";
				var handlerMethodMeta = { name="viewlet", private=true, cacheable=false };

				mockColdbox.$( "handlerExists" ).$args( viewlet ).$results( true );
				service.$( "_getHandlerMethodMeta" ).$args( viewlet ).$results( handlerMethodMeta );
				service.$( "$isFeatureEnabled" ).$args( "fullPageCaching" ).$results( false );

				expect( service.isViewletDelayedByDefault( viewlet ) ).toBe( false );
			} );
		} );
	}

	private function _getService(){
		variables.mockColdbox         = CreateStub();
		variables.mockContentRenderer = CreateEmptyMock( "preside.system.services.rendering.ContentRendererService" );

		var service = CreateMock( object=new preside.system.services.rendering.DelayedViewletRendererService(
			  defaultHandlerAction = "index"
			, contentRendererService = mockContentRenderer
		) );

		service.$( "$getColdbox", mockColdbox );
		service.$( "$isFeatureEnabled", true );

		return service;
	}


}