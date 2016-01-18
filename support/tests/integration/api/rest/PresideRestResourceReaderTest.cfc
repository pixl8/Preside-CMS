component extends="testbox.system.BaseSpec"{

	function beforeAll() {
		variables.resourceReader = new preside.system.services.rest.PresideRestResourceReader();
	}

	function run(){

		describe( "isValidResource", function(){

			it( "should return false when resource CFC file does not contain a restUri attribute", function(){
				expect( resourceReader.isValidResource( "resources.rest.InvalidResource" ) ).toBeFalse();
			} );

			it( "should return true when the resource CFC file _does_ contain a restUri attribute", function(){
				expect( resourceReader.isValidResource( "resources.rest.DumbButValidResource" ) ).toBeTrue();
			} );

			it( "should return true when the resource CFC file extends a CFC with a restUri attribute", function(){
				expect( resourceReader.isValidResource( "resources.rest.ExtendedDumbButValidResource" ) ).toBeTrue();
			} );

		} );

		describe( "readUri", function(){

			it( "should return struct containing uriPattern and tokens keys", function(){
				var parsedUri = resourceReader.readUri( "/some/uri/" );

				expect( parsedUri.keyExists( "uriPattern" ) ).toBe( true );
				expect( parsedUri.keyExists( "tokens" ) ).toBe( true );
			} );

			it( "should replace named tokens with regex pattern for resulting uriPattern", function(){
				var parsedUri = resourceReader.readUri( "/some/{token}/another/{token-x}" );

				expect( parsedUri.uriPattern ).toBe( "^/some/(.*?)/another/(.*?)$" );
			} );

			it( "should extract out each named token into an array of token names", function(){
				var parsedUri = resourceReader.readUri( "/some/{token}/another/{token-x}" );

				expect( parsedUri.tokens ).toBe( [ "token", "token-x" ] );
			} );
		} );

		describe( "readResource", function(){
			it( "should return an array of structs for each URI pattern defined in the resource", function(){
				var resource = resourceReader.readResource( "resources.rest.TestResource", "/v2" );

				expect( resource.len() ).toBe( 2 );
			} );

			it( "should convert URI patterns into regex representations", function(){
				var resource = resourceReader.readResource( "resources.rest.TestResource", "/v2" );

				expect( resource.len() ).toBe( 2 );
				expect( resource[1].uriPattern ).toBe( "^/test/(.*?)$" );
				expect( resource[2].uriPattern ).toBe( "^/test/(.*?)/(.*?)/$" );
			} );

			it( "should extract out named arguments to a resource URI into its own array", function(){
				var resource = resourceReader.readResource( "resources.rest.TestResource", "/v2" );

				expect( resource.len() ).toBe( 2 );
				expect( resource[1].tokens ).toBe( [ "pattern" ] );
				expect( resource[2].tokens ).toBe( [ "pattern", "id" ] );

			} );

			it( "should map http verbs to functions defined in the cfc", function(){
				var resource = resourceReader.readResource( "resources.rest.TestResource", "/v2" );

				expect( resource.len() ).toBe( 2 );

				for( var i=1; i<=2; i++ ) {
					expect( resource[i].verbs ?: "" ).toBe( {
						  "get"    = "get"
						, "put"    = "putDatatest"
						, "delete" = "delete"
						, "post"   = "postTest"
					} );
				}
			} );

			it( "should identify the relative handler name in each resource result prepended with the API path", function(){
				var resource = resourceReader.readResource( "resources.rest.TestResource", "/api/v2" );

				expect( resource.len() ).toBe( 2 );

				for( var i=1; i<=2; i++ ) {
					expect( resource[i].handler ?: "" ).toBe( "api.v2.TestResource" );
				}
			} );
		} );

		describe( "readResourceDirectories()", function(){
			it( "should return a resource arrays grouped into API endpoints from all the .cfc resource files in the passed array of directories", function(){
				var resources = resourceReader.readResourceDirectories( [ "/resources/rest/dir1", "/resources/rest/dir2" ] );
				expect( resources ).toBe( {
					"/" = [{
						  handler    			= "RootApiResource"
						, tokens     			= []
						, uriPattern 			= "^/root/match/$"
						, verbs      			= { post="post" }
						, requiredParameters	= { post=[] }
						, parameterTypes      	= { post={} }
					}],
					"/api1" = [{
						  handler    			= "api1.ResourceX"
						, tokens     			= [ "pattern", "id" ]
						, uriPattern 			= "^/test/(.*?)/(.*?)/$"
						, verbs      			= { post="post", get="get", delete="delete", put="putDataTest" }
						, requiredParameters	= { delete=[], get=[], put=[] }
						, parameterTypes 		= { delete={}, get={}, put={} }
						
					},{
						  handler    			= "api1.ResourceX"
						, tokens     			= [ "pattern" ]
						, uriPattern 			= "^/test/(.*?)$"
						, verbs      			= { post="post", get="get", delete="delete", put="putDataTest" }
						, requiredParameters	= { delete=[], get=[], put=[] }
						, parameterTypes 		= { delete={}, get={}, put={} }
					}],
					"/api1/subapi" = [{
						  handler    			= "api1.subapi.ParamAwareResource"
						, tokens     			= [ "param1" ]
						, uriPattern 			= "^/my/paramaware/pattern/(.*?)$"
						, verbs      			= { get="get" }
						, requiredParameters	= { get=["param1", "x"] }
						, parameterTypes      	= { get={param1="string", x="numeric", y="date", z="uuid"} }
					},{
						  handler    			= "api1.subapi.TestResource"
						, tokens     			= []
						, uriPattern 			= "^/my/pattern/$"
						, verbs      			= { get="get" }
						, requiredParameters	= { get=[] }
						, parameterTypes      	= { get={} }
					}],
					"/api2" = [{
						  handler    			= "api2.AnotherResource"
						, tokens     			= [ "pattern", "here" ]
						, uriPattern 			= "^/another/matching/(.*?)/(.*?)$"
						, verbs      			= { post="post" }
						, requiredParameters	= { post=[] }
						, parameterTypes      	= { post={} }
					}]
				});
			} );

		} );

	}

}