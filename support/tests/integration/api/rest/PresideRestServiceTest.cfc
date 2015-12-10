component extends="testbox.system.BaseSpec"{

	function run(){

		describe( "getResourceForUri()", function(){

			it( "should find first regex match for a passed URI", function(){
				var restService = getService();

				expect( restService.getResourceForUri( "/api1/test/my-pattern/#CreateUUId()#/" ) ).toBe( {
					  handler    = "api1.ResourceX"
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

			it( "it should call the matched coldbox handler for the given request and http method", function(){
				var uri             = "/some/uri/23";
				var restService     = getService();
				var resourceHandler = {
					  handler    = "myResource"
					, tokens     = [ "whatever", "thisisjust", "atest" ]
					, uriPattern = "/test/(.*?)/(.*?)/"
					, verbs      = { post="post", get="get", delete="delete", put="putDataTest" }
				};
				var verb = "put";
				var mockRequestContext = getMockRequestContext();
				var mockTokens = {
					  completelyMocked = true
					, tokens           = "test"
				};
				var mockResponse = createEmptyMock( "preside.system.services.rest.PresideRestResponse" );
				var expectedArgs = { response=mockResponse };
				expectedArgs.append( mockTokens );

				mockResponse.id = CreateUUId();

				restService.$( "processResponse" );
				restService.$( "createRestResponse", mockResponse );
				restService.$( "getResourceForUri" ).$args( uri ).$results( resourceHandler );
				restService.$( "extractTokensFromUri"   ).$args(
					  uriPattern = resourceHandler.uriPattern
					, tokens     = resourceHandler.tokens
					, uri        = uri
				).$results( mockTokens );
				mockRequestContext.$( "getHttpMethod", verb );

				mockController.$( "runEvent" );

				restService.processRequest( uri=uri, requestContext=mockRequestContext );

				var callLog = mockController.$callLog().runEvent;

				expect( callLog.len() ).toBe( 1 );


				expect( callLog[1].event ).toBe( "rest-apis.myResource.putDataTest" );
				expect( callLog[1].prePostExempt ).toBe( false );
				expect( callLog[1].private ).toBe( true  );
				expect( callLog[1].eventArguments ).toBe( expectedArgs );
			} );

		it( "it should call processResponse to render the result", function(){
				var uri             = "/some/uri/23";
				var restService     = getService();
				var resourceHandler = {
					  handler    = "myResource"
					, tokens     = [ "whatever", "thisisjust", "atest" ]
					, uriPattern = "/test/(.*?)/(.*?)/"
					, verbs      = { post="post", get="get", delete="delete", put="putDataTest" }
				};
				var verb = "put";
				var mockRequestContext = getMockRequestContext();
				var mockTokens = {
					  completelyMocked = true
					, tokens           = "test"
				};
				var mockResponse = createEmptyMock( "preside.system.services.rest.PresideRestResponse" );
				var expectedArgs = { response=mockResponse };
				expectedArgs.append( mockTokens );

				mockResponse.id = CreateUUId();

				restService.$( "processResponse" );
				restService.$( "createRestResponse", mockResponse );
				restService.$( "getResourceForUri" ).$args( uri ).$results( resourceHandler );
				restService.$( "extractTokensFromUri"   ).$args(
					  uriPattern = resourceHandler.uriPattern
					, tokens     = resourceHandler.tokens
					, uri        = uri
				).$results( mockTokens );
				mockRequestContext.$( "getHttpMethod", verb );

				mockController.$( "runEvent" );

				restService.processRequest( uri=uri, requestContext=mockRequestContext );

				var callLog = restService.$callLog().processResponse;

				expect( callLog.len() ).toBe( 1 );
				expect( callLog[1].response ).toBe( mockResponse );
				expect( callLog[1].requestContext.getInstanceIdForComparison() ).toBe( mockRequestContext.getInstanceIdForComparison() );
			} );

		} );

		describe( "processResponse()", function(){
			it( "should call renderData on the request context", function(){
				var restService        =  getService();
				var mockRequestContext = getMockRequestContext();
				var response           = new preside.system.services.rest.PresideRestResponse();

				restService.processResponse( response, mockRequestContext );

				expect( mockRequestContext.$callLog().renderData.len() ).toBe( 1 );

			} );

			it( "should pass the response renderer to the 'type' argument in renderData", function(){
				var restService        =  getService();
				var mockRequestContext = getMockRequestContext();
				var response           = new preside.system.services.rest.PresideRestResponse();

				response.setRenderer( "jsonp" );
				restService.processResponse( response, mockRequestContext );

				var renderDataArgs = mockRequestContext.$callLog().renderData[1];
				expect( renderDataArgs.keyExists( "type" ) ).toBeTrue();
				expect( renderDataArgs.type ).toBe( "jsonp" );
			} );

			it( "should pass the response mime type to the 'contenttype' argument in renderData", function(){
				var restService        =  getService();
				var mockRequestContext = getMockRequestContext();
				var response           = new preside.system.services.rest.PresideRestResponse();

				response.setMimeType( "text/plain" );
				restService.processResponse( response, mockRequestContext );

				var renderDataArgs = mockRequestContext.$callLog().renderData[1];
				expect( renderDataArgs.keyExists( "contentType" ) ).toBeTrue();
				expect( renderDataArgs.contentType ).toBe( "text/plain" );
			} );

			it( "should pass the response status code to the 'statusCode' argument in renderData", function(){
				var restService        =  getService();
				var mockRequestContext = getMockRequestContext();
				var response           = new preside.system.services.rest.PresideRestResponse();

				response.setStatusCode( 451 );
				restService.processResponse( response, mockRequestContext );

				var renderDataArgs = mockRequestContext.$callLog().renderData[1];
				expect( renderDataArgs.keyExists( "statusCode" ) ).toBeTrue();
				expect( renderDataArgs.statusCode ).toBe( 451 );
			} );

			it( "should pass the response status text to the 'statusText' argument in renderData", function(){
				var restService        =  getService();
				var mockRequestContext = getMockRequestContext();
				var response           = new preside.system.services.rest.PresideRestResponse();

				response.setStatusText( "This content has been censored and cannot therefor be shown" );
				restService.processResponse( response, mockRequestContext );

				var renderDataArgs = mockRequestContext.$callLog().renderData[1];
				expect( renderDataArgs.keyExists( "statusText" ) ).toBeTrue();
				expect( renderDataArgs.statusText ).toBe( "This content has been censored and cannot therefor be shown" );
			} );

			it( "should pass the response data to the 'data' argument in renderData", function(){
				var restService        =  getService();
				var mockRequestContext = getMockRequestContext();
				var response           = new preside.system.services.rest.PresideRestResponse();

				response.setData( { test="data" } );
				restService.processResponse( response, mockRequestContext );

				var renderDataArgs = mockRequestContext.$callLog().renderData[1];
				expect( renderDataArgs.keyExists( "data" ) ).toBeTrue();
				expect( renderDataArgs.data ).toBe( { test="data" } );
			} );

			it( "should pass an empty string to the renderData 'data' argument, when the data in the response object is NULL", function(){
				var restService        =  getService();
				var mockRequestContext = getMockRequestContext();
				var response           = new preside.system.services.rest.PresideRestResponse();

				response.noData();
				restService.processResponse( response, mockRequestContext );

				var renderDataArgs = mockRequestContext.$callLog().renderData[1];
				expect( renderDataArgs.keyExists( "data" ) ).toBeTrue();
				expect( renderDataArgs.data ).toBe( "" );
			} );

			it( "should call setHttpHeader() on the request context for each header set in the response", function(){
				var restService        =  getService();
				var mockRequestContext = getMockRequestContext();
				var response           = new preside.system.services.rest.PresideRestResponse();

				response.setHeaders({
					  "X-My-Header"      = "my value"
					, "X-Another-Header" = "another value"
					, "X-good-stuff"     = "yes"
				});

				restService.processResponse( response, mockRequestContext );

				var callLog = mockRequestContext.$callLog().setHttpHeader;

				expect( callLog.len() ).toBe( 3 );

				callLog.sort( function( a, b ) {
					return LCase( SerializeJson( a ) ) > LCase( SerializeJson( b ) ) ? 1 : -1;
				} );
				expect( callLog ).toBe( [
					  { name="X-Another-Header", value="another value" }
					, { name="X-good-stuff"    , value="yes"           }
					, { name="X-My-Header"     , value="my value"      }
				] );
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

	private any function getMockRequestContext() {
		var rc = createEmptyMock( "coldbox.system.web.context.RequestContext" );

		rc.$( "getHttpMethod", "get" );
		rc.$( "setHttpHeader", rc );
		rc.$( "renderData", rc );
		rc.$( "getInstanceIdForComparison", CreateUUId() );

		return rc;
	}

}