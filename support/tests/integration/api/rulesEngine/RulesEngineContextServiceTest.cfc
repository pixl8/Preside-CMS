component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "listContexts()", function(){
			it( "should return an empty array when no contexts configured", function(){
				expect( _getService({}).listContexts() ).toBe( [] );
			} );

			it( "should return an array of configured context, each element containing a struct with keys id, title, description and iconClass (the latter three being derived by convention from the ID using i18n properties)", function(){
				var contexts = _getDefaultConfiguredContexts();
				var service  = _getService( contexts );
				var expected = [];

				for( var id in contexts ) {
					service.$( "$translateResource" ).$args( "rules.contexts:#id#.title"       ).$results( id & "title"       );
					service.$( "$translateResource" ).$args( "rules.contexts:#id#.description" ).$results( id & "description" );
					service.$( "$translateResource" ).$args( "rules.contexts:#id#.iconClass"   ).$results( id & "icon"        );

					expected.append({
						  id          = id
						, title       = id & "title"
						, description = id & "description"
						, iconClass   = id & "icon"
					});
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
	}

// PRIVATE HELPERS
	private any function _getService( struct contexts=_getDefaultlConfiguredContexts() ) {
		var service = createMock( object=new preside.system.services.rulesEngine.RulesEngineContextService(
			configuredContexts = arguments.contexts
		) );

		return service;
	}

	private struct function _getDefaultConfiguredContexts() {
		return {
			  webrequest = { subcontexts=[ "user", "page" ] }
			, user       = {}
			, page       = {}
		};
	}

}