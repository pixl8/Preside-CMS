component extends="testbox.system.BaseSpec"{

	function run(){

		describe( "getResourceForUri()", function(){

			it( "should find first regex match for a passed URI", function(){
				var restService = getService();

				expect( restService.getResourceForUri( "/test/my-pattern/#CreateUUId()#/" ) ).toBe( {
					  handler    = "ResourceX"
					, tokens     = [ "pattern", "id" ]
					, uriPattern = "/test/(.*?)/(.*?)/"
					, verbs      = { post="post", get="get", delete="delete", put="putDataTest" }
				} );
			} );

			it( "should return an empty struct when no resource is found", function(){
				var restService = getService();

				expect( restService.getResourceForUri( "/whatever/this/is/#CreateUUId()#/" ) ).toBe( {} );
			} );

		} );

		describe( "extractTokensFromUri", function(){
			it( "should extract tokens from a resource URI from the actual incoming URI as a struct", function(){
				var restService = getService();
				var id     = CreateUUId();
				var object = "myObject";

				expect( restService.extractTokensFromUri(
					  uriPattern = "/object/(.*?)/(.*?)/"
					, tokens     = [ "object", "id" ]
					, uri        = "/object/#object#/#id#/"
				) ).toBe( { object=object, id=id } );
			} );
		} );

		describe( "processRequest", function(){

			it( "it should call the matched coldbox handler for the given request and passed verb", function(){
				var uri             = "/some/uri/23";
				var restService     = getService();
				var resourceHandler = {
					  handler    = "myResource"
					, tokens     = [ "whatever", "thisisjust", "atest" ]
					, uriPattern = "/test/(.*?)/(.*?)/"
					, verbs      = { post="post", get="get", delete="delete", put="putDataTest" }
				};
				var verb = "put";
				var mockTokens = {
					  completelyMocked = true
					, tokens           = "test"
				};
				var mockResponse = createEmptyMock( "preside.system.services.rest.PresideRestResponse" );
				var expectedArgs = { response=mockResponse };
				expectedArgs.append( mockTokens );

				mockResponse.id = CreateUUId();

				restService.$( "createRestResponse", mockResponse );
				restService.$( "getResourceForUri" ).$args( uri ).$results( resourceHandler );
				restService.$( "extractTokensFromUri"   ).$args(
					  uriPattern = resourceHandler.uriPattern
					, tokens     = resourceHandler.tokens
					, uri        = uri
				).$results( mockTokens );

				mockController.$( "runEvent" );

				restService.processRequest( uri=uri, verb=verb );

				var callLog = mockController.$callLog().runEvent;

				expect( callLog.len() ).toBe( 1 );


				expect( callLog[1].event ).toBe( "rest-resources.myResource.putDataTest" );
				expect( callLog[1].prePostExempt ).toBe( false );
				expect( callLog[1].private ).toBe( true  );
				expect( callLog[1].eventArguments ).toBe( expectedArgs );
			} );
		} );

	}

	private any function getService( ) {
		variables.mockController = createStub();
		return createMock( object=new preside.system.services.rest.PresideRestService(
			  controller          = mockController
			, resourceDirectories = [ "/resources/rest/dir1", "/resources/rest/dir2" ]
		) );
	}

}