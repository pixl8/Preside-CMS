component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "listContexts()", function(){
			it( "should return an empty array when no contexts configured", function(){
				expect( _getService({}).listContexts() ).toBe( [] );
			} );

			it( "should return an array of visible configured contexts, each element containing a struct with keys id, filterObject, title, description and iconClass (the latter three being derived by convention from the ID using i18n properties)", function(){
				var contexts = _getDefaultConfiguredContexts();
				var service  = _getService( contexts );
				var expected = [];

				for( var id in contexts ) {
					if ( !contexts[id].keyExists( "visible" ) || contexts[id].visible ) {
						service.$( "$translateResource" ).$args( "rules.contexts:#id#.title"       ).$results( id & "title"       );
						service.$( "$translateResource" ).$args( "rules.contexts:#id#.description" ).$results( id & "description" );
						service.$( "$translateResource" ).$args( "rules.contexts:#id#.iconClass"   ).$results( id & "icon"        );

						expected.append({
							  id           = id
							, title        = id & "title"
							, description  = id & "description"
							, iconClass    = id & "icon"
							, object       = contexts[id].object ?: ""
						});
					}
				}

				expected.sort( function( a, b ){
					return a.title > b.title ? 1 : -1;
				} );

				expect( service.listContexts() ).toBe( expected );
			} );
		} );

		describe( "listValidExpressionContextsForParentContexts()", function(){
			it( "should return an array of all sub contexts (and their sub contexts) along with the parent context when the given context has sub contexts", function(){
				var contexts = {
					  webrequest = { subcontexts=[ "user", "page" ] }
					, user       = { subcontexts=[ "somethingelse" ] }
					, page       = {}
					, somethingelse = {}
				};
				var service  = _getService( contexts );

				var validContexts = service.listValidExpressionContextsForParentContexts( [ "webrequest", "test" ] );

				validContexts.sort( "textnocase" );

				expect( validContexts ).toBe( [ "page", "somethingelse", "test", "user", "webrequest" ] );
			} );

			it( "should return an array with just the given parent context when the context has no sub contexts", function(){
				var contexts = {
					  webrequest = { subcontexts=[ "user", "page" ] }
					, user       = { subcontexts=[ "somethingelse" ] }
					, page       = {}
					, somethingelse = {}
				};
				var service  = _getService( contexts );

				var validContexts = service.listValidExpressionContextsForParentContexts( [ "page" ] );

				expect( validContexts ).toBe( [ "page" ] );
			} );
		} );

		describe( "expandContexts()", function(){
			it( "should expand an array of context to include any parent contexts", function(){
				var contexts = {
					  webrequest = { subcontexts=[ "user", "page" ] }
					, user       = { subcontexts=[ "somethingelse" ] }
					, page       = {}
					, somethingelse = {}
				};
				var service  = _getService( contexts );

				var expandedContexts = service.expandContexts( [ "somethingelse", "test" ] );

				expandedContexts.sort( "textnocase" );

				expect( expandedContexts ).toBe( [ "somethingelse", "test", "user", "webrequest" ] );
			} );
		} );

		describe( "getContextObject", function(){
			it( "should return the configured object for the context", function(){
				var service = _getService();

				expect( service.getContextObject( "user" ) ).toBe( "website_user" );
			} );

			it( "should return an empty string when the context does not have a configured object", function(){
				var service = _getService();

				expect( service.getContextObject( "webrequest" ) ).toBe( "" );
			} );

			it( "should return an empty string when the context does not exist", function(){
				var service = _getService();

				expect( service.getContextObject( "somecontext" ) ).toBe( "" );
			} );
		} );

		describe( "addContext()", function(){
			it( "should register the new context based on supplied arguments", function(){
				var service = _getService({});

				service.addContext(
					  id      = "object_test"
					, object  = "test"
					, visible = false
				);

				expect( service.listContexts() ).toBe( [] );
				expect( service.getContextObject( "object_test" ) ).toBe( "test" );
			} );
		} );

		describe( "getContextPayload()", function(){
			it( "should call the convention based handler action, if it exists, to fetch the payload for a given context", function(){
				var service = _getService();
				var context = "somecontext";
				var expectedHandler = "rules.contexts.somecontext.getPayload";
				var payload = { test=CreateUUId() };

				service.$( "listValidExpressionContextsForParentContexts" ).$args( [ context ] ).$results( [ context ] );
				mockColdbox.$( "handlerExists" ).$args( expectedHandler ).$results( true );
				mockColdbox.$( "runEvent" ).$args(
					  event          = expectedHandler
					, eventArguments = {}
					, private        = true
					, prePostExempt  = true
				).$results( payload );

				expect( service.getContextPayload( context ) ).toBe( payload );
			} );

			it( "should return an empty struct when convention based handler for the context does not exist", function(){
				var service = _getService();
				var context = "somecontext";
				var expectedHandler = "rules.contexts.somecontext.getPayload";
				var payload = { test=CreateUUId() };

				service.$( "listValidExpressionContextsForParentContexts" ).$args( [ context ] ).$results( [ context ] );
				mockColdbox.$( "handlerExists" ).$args( expectedHandler ).$results( false );
				mockColdbox.$( "runEvent" ).$args(
					  event          = expectedHandler
					, eventArguments = {}
					, private        = true
					, prePostExempt  = true
				).$results( payload );

				expect( service.getContextPayload( context ) ).toBe( {} );
			} );

			it( "should pass any additionally passed arguments through as eventArguments to the convention based handler", function(){
				var service = _getService();
				var context = "somecontext";
				var expectedHandler = "rules.contexts.somecontext.getPayload";
				var payload = { test=CreateUUId() };
				var args    = { blah=CreateUUId(), "test-#CreateUUId()#"=Now() };

				service.$( "listValidExpressionContextsForParentContexts" ).$args( [ context ] ).$results( [ context ] );
				mockColdbox.$( "handlerExists" ).$args( expectedHandler ).$results( true );
				mockColdbox.$( "runEvent" ).$args(
					  event          = expectedHandler
					, eventArguments = args
					, private        = true
					, prePostExempt  = true
				).$results( payload );

				expect( service.getContextPayload( context, args ) ).toBe( payload );
			} );

			it( "should build up payload of expanded contexts when context expands to be multiple contexts", function(){
				var service = _getService();
				var context = "somecontext";
				var expanded = [ "somecontext", "user", "stuffz" ];
				var payloads = {
					  somecontext = { test=CreateUUId() }
					, user        = { test=CreateUUId(), foo="bar" }
					, stuffz      = { foo="love", it=Now() }
				};
				var args    = { blah=CreateUUId(), "test-#CreateUUId()#"=Now() };

				service.$( "listValidExpressionContextsForParentContexts" ).$args( [ context ] ).$results( expanded );
				for( var cx in expanded ) {
					var expectedHandler = "rules.contexts.#cx#.getPayload";

					mockColdbox.$( "handlerExists" ).$args( expectedHandler ).$results( true );
					mockColdbox.$( "runEvent" ).$args(
						  event          = expectedHandler
						, eventArguments = args
						, private        = true
						, prePostExempt  = true
					).$results( payloads[ cx ] );
				}

				expect( service.getContextPayload( context, args ) ).toBe( {
					  foo  = payloads.stuffz.foo
					, it   = payloads.stuffz.it
					, test = payloads.user.test
				} );
			} );
		} );
	}

// PRIVATE HELPERS
	private any function _getService( struct contexts=_getDefaultConfiguredContexts() ) {
		var service = createMock( object=new preside.system.services.rulesEngine.RulesEngineContextService(
			configuredContexts = arguments.contexts
		) );

		mockColdbox = createEmptyMock( "preside.system.coldboxModifications.Controller" );
		service.$( "$getColdbox", mockColdbox );

		return service;
	}

	private struct function _getDefaultConfiguredContexts() {
		return {
			  webrequest   = { subcontexts=[ "user", "page" ] }
			, user         = { object="website_user" }
			, page         = { object="page", visible=true }
			, object_event = { object="event", visible=false }
		};
	}

}