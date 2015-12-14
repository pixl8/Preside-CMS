component extends="testbox.system.BaseSpec"{

	function run(){

		describe( "getApiForUri()", function(){
			it( "should find the most detailed API match for the given URI", function(){
				var restService = getService();

				expect( restService.getApiForUri( "/api1/subapi/my/pattern/" ) ).toBe( "/api1/subapi" );
			} );
		} );

		describe( "getResourceForUri()", function(){

			it( "should find first regex match for a passed URI", function(){
				var restService = getService();

				expect( restService.getResourceForUri( "/api1/test/my-pattern/#CreateUUId()#/" ) ).toBe( {
					  handler    = "api1.ResourceX"
					, tokens     = [ "pattern", "id" ]
					, uriPattern = "^/test/(.*?)/(.*?)/$"
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

		describe( "onRestRequest", function(){

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
				mockResponse.$( "isFinished", false );

				restService.$( "processResponse" );
				restService.$( "createRestResponse", mockResponse );
				restService.$( "getResourceForUri" ).$args( uri ).$results( resourceHandler );
				restService.$( "extractTokensFromUri"   ).$args(
					  uriPattern = resourceHandler.uriPattern
					, tokens     = resourceHandler.tokens
					, uri        = uri
				).$results( mockTokens );
				restService.$( "getVerb" ).$args( mockRequestContext ).$results( verb );

				mockController.$( "runEvent" );

				restService.onRestRequest( uri=uri, requestContext=mockRequestContext );

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
				mockResponse.$( "isFinished", false );

				restService.$( "processResponse" );
				restService.$( "createRestResponse", mockResponse );
				restService.$( "getResourceForUri" ).$args( uri ).$results( resourceHandler );
				restService.$( "extractTokensFromUri"   ).$args(
					  uriPattern = resourceHandler.uriPattern
					, tokens     = resourceHandler.tokens
					, uri        = uri
				).$results( mockTokens );
				restService.$( "getVerb" ).$args( mockRequestContext ).$results( verb );

				mockController.$( "runEvent" );

				restService.onRestRequest( uri=uri, requestContext=mockRequestContext );

				var callLog = restService.$callLog().processResponse;

				expect( callLog.len() ).toBe( 1 );
				expect( callLog[1].response ).toBe( mockResponse );
				expect( callLog[1].requestContext.getInstanceIdForComparison() ).toBe( mockRequestContext.getInstanceIdForComparison() );
			} );

			it( "should set error on the response when no resource handler exists for the request", function(){
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
				mockResponse.$( "setError" );
				mockResponse.id = CreateUUId();
				mockResponse.$( "isFinished", false );

				restService.$( "processResponse" );
				restService.$( "getVerb" ).$args( mockRequestContext ).$results( verb );
				restService.$( "createRestResponse", mockResponse );
				restService.$( "getResourceForUri" ).$args( uri ).$results( {} );

				restService.onRestRequest( uri=uri, requestContext=mockRequestContext );

				var log = mockResponse.$callLog().setError;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( {
					  errorCode = 404
					, title     = "REST API Resource not found"
					, type      = "rest.resource.not.found"
					, message   = "The requested resource, [/some/uri/23], did not match any resources in the Preside REST API"
				} );

			} );

			it( "should set error on the response when resource handler exists, but not for the current HTTP VERB in use", function(){
				var uri             = "/some/uri/23";
				var restService     = getService();
				var resourceHandler = {
					  handler    = "myResource"
					, tokens     = [ "whatever", "thisisjust", "atest" ]
					, uriPattern = "/test/(.*?)/(.*?)/"
					, verbs      = { post="post", get="get", delete="delete" }
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
				mockResponse.$( "isFinished", false );

				restService.$( "processResponse" );
				restService.$( "createRestResponse", mockResponse );
				restService.$( "getResourceForUri" ).$args( uri ).$results( resourceHandler );
				restService.$( "extractTokensFromUri"   ).$args(
					  uriPattern = resourceHandler.uriPattern
					, tokens     = resourceHandler.tokens
					, uri        = uri
				).$results( mockTokens );
				restService.$( "getVerb" ).$args( mockRequestContext ).$results( verb );
				mockResponse.$( "setError" );
				mockController.$( "runEvent" );

				restService.onRestRequest( uri=uri, requestContext=mockRequestContext );

				var log = mockResponse.$callLog().setError;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( {
					  errorCode = 405
					, title     = "REST API Method not supported"
					, type      = "rest.method.unsupported"
					, message   = "The requested resource, [/some/uri/23], does not support the [#verb#] method"
				} );
			} );

			it( "should announce a onRestRequest interception point as the first announcement", function(){
				var uri                = "/some/uri/23";
				var restService        = getService();
				var mockRequestContext = getMockRequestContext();
				var mockResponse       = createEmptyMock( "preside.system.services.rest.PresideRestResponse" );
				var verb               = "DELETE";

				restService.$( "processRequest"  );
				restService.$( "processResponse" );
				restService.$( "createRestResponse", mockResponse );
				restService.$( "getVerb" ).$args( mockRequestContext ).$results( verb );
				mockResponse.$( "isFinished", false );

				restService.onRestRequest( uri=uri, requestContext=mockRequestContext );

				var log = restService.$callLog()._announceInterception;
				expect( log.len() > 0 ).toBe( true );
				expect( log[1] ).toBe([ "onRestRequest", { uri=uri, verb=verb, response=mockResponse } ]);
			} );

		} );

		describe( "processRequest", function(){
			it( "should not set error when verb is HEAD and no explicit HEAD handler exists for the resource", function(){
				var restService        = getService();
				var dummyUri           = "/some/test/uri/";
				var dummyResource      = { verbs={ "GET"="someGetMethod" } };
				var mockRequestContext = getMockRequestContext();
				var mockResponse       = createEmptyMock( "preside.system.services.rest.PresideRestResponse" );

				restService.$( "invokeRestResourceHandler" );
				restService.$( "getResourceForUri" ).$args( dummyUri ).$results( dummyResource );
				mockResponse.$( "setError" );

				restService.processRequest(
					  uri            = dummyUri
					, verb           = "HEAD"
					, requestContext = mockRequestContext
					, response       = mockResponse
				);

				var callLog = mockResponse.$callLog().setError;

				expect( callLog.len() ).toBe( 0 );
			} );

			it( "should not set error when verb is OPTIONS and no explicit OPTIONS handler exists for the resource", function(){
				var restService        = getService();
				var dummyUri           = "/some/test/uri/";
				var dummyResource      = { verbs={ "GET"="someGetMethod", "POST"="somePostMethod" } };
				var mockRequestContext = getMockRequestContext();
				var mockResponse       = createEmptyMock( "preside.system.services.rest.PresideRestResponse" );

				restService.$( "invokeRestResourceHandler" );
				restService.$( "processOptionsRequest" );
				restService.$( "getResourceForUri" ).$args( dummyUri ).$results( dummyResource );
				mockResponse.$( "setError" );

				restService.processRequest(
					  uri            = dummyUri
					, verb           = "OPTIONS"
					, requestContext = mockRequestContext
					, response       = mockResponse
				);

				var callLog = mockResponse.$callLog().setError;

				expect( callLog.len() ).toBe( 0 );
			} );

			it( "should process OPTIONS requests with using the processOptionsRequest method if no specific OPTIONS method supplied by the resource", function(){
				var restService        = getService();
				var dummyUri           = "/some/test/uri/";
				var dummyResource      = { verbs={ "GET"="someGetMethod", "POST"="somePostMethod" } };
				var mockRequestContext = getMockRequestContext();
				var mockResponse       = createEmptyMock( "preside.system.services.rest.PresideRestResponse" );

				restService.$( "invokeRestResourceHandler" );
				restService.$( "processOptionsRequest" );
				restService.$( "getResourceForUri" ).$args( dummyUri ).$results( dummyResource );
				mockResponse.$( "setError" );

				restService.processRequest(
					  uri            = dummyUri
					, verb           = "OPTIONS"
					, requestContext = mockRequestContext
					, response       = mockResponse
				);

				var callLog = restService.$callLog();

				expect( callLog.processOptionsRequest.len() ).toBe( 1 );
				expect( callLog.invokeRestResourceHandler.len() ).toBe( 0 );
			} );

			it( "should process OPTIONS requests using the supplied OPTIONS method of the resource when defined in the resource", function(){
				var restService        = getService();
				var dummyUri           = "/some/test/uri/";
				var dummyResource      = { verbs={ "GET"="someGetMethod", "POST"="somePostMethod", "OPTIONS"="someOptionsMethod" } };
				var mockRequestContext = getMockRequestContext();
				var mockResponse       = createEmptyMock( "preside.system.services.rest.PresideRestResponse" );

				restService.$( "invokeRestResourceHandler" );
				restService.$( "processOptionsRequest" );
				restService.$( "getResourceForUri" ).$args( dummyUri ).$results( dummyResource );
				mockResponse.$( "setError" );

				restService.processRequest(
					  uri            = dummyUri
					, verb           = "OPTIONS"
					, requestContext = mockRequestContext
					, response       = mockResponse
				);

				var callLog = restService.$callLog();

				expect( callLog.processOptionsRequest.len() ).toBe( 0 );
				expect( callLog.invokeRestResourceHandler.len() ).toBe( 1 );
			} );
		} );

		describe( "invokeRestResourceHandler", function(){
			it( "should call the GET method of a resource when verb is HEAD and no specific HEAD method exists", function(){
				var restService        = getService();
				var resource           = { uriPattern="/some/uri/", handler="somehandler", tokens=[], verbs={ GET="testGetMethod" } };
				var uri                = "/some/uri/"
				var verb               = "HEAD";
				var mockResponse       = createEmptyMock( "preside.system.services.rest.PresideRestResponse" );
				var mockRequestContext = getMockRequestContext();

				restService.$( "extractTokensFromUri", {} );
				mockResponse.$( "isFinished", false );
				mockResponse.$( "setError" );
				mockController.$( "runEvent" );

				restService.invokeRestResourceHandler(
					  resource       = resource
					, uri            = uri
					, verb           = verb
					, response       = mockResponse
					, requestContext = mockRequestContext
				);

				var callLog = mockController.$callLog().runEvent;

				expect( callLog.len() ).toBe( 1 );
				expect( callLog[1].event ).toBe( "rest-apis.somehandler.testGetMethod" );
			} );
		} );

		describe( "processOptionsRequest()", function(){
			it( "should set a 400 error when 'Origin' request header is missing", function(){
				var restService        = getService();
				var resource           = { uriPattern="/some/uri/", handler="somehandler", tokens=[], verbs={ GET="testGetMethod", PUT="put", DELETE="delete" } };
				var response           = new preside.system.services.rest.PresideRestResponse();
				var mockRequestContext = getMockRequestContext();
				var uri                = "/some/test/304958/"

				response.setData( { test=true } );

				restService.processOptionsRequest( resource=resource, response=response, requestContext=mockRequestContext, uri=uri );

				expect( response.getStatusCode() ).toBe( 400 );
				expect( response.getStatusText() ).toBe( "Bad request" );
				expect( response.getRenderer() ).toBe( "json" );
				expect( response.getData() ).toBe( {
					  type   = "rest.options.missing.origin"
					, status = 400
					, title  = "Bad request"
					, detail = "Insufficient information. Origin request header needed."
				} );
			} );

			it( "should set a 400 error when 'Access-Control-Request-Method' request header is missing", function(){
				var restService        = getService();
				var resource           = { uriPattern="/some/uri/", handler="somehandler", tokens=[], verbs={ GET="testGetMethod", PUT="put", DELETE="delete" } };
				var response           = new preside.system.services.rest.PresideRestResponse();
				var mockRequestContext = getMockRequestContext();
				var uri                = "/some/test/304958/"

				response.setData( { test=true } );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Origin", default="" ).$results( "https://mysite.com" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Method", default="" ).$results( "" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Headers", default="" ).$results( "" );

				restService.processOptionsRequest( resource=resource, response=response, requestContext=mockRequestContext, uri=uri );

				expect( response.getStatusCode() ).toBe( 400 );
				expect( response.getStatusText() ).toBe( "Bad request" );
				expect( response.getRenderer() ).toBe( "json" );
				expect( response.getData() ).toBe( {
					  type   = "rest.options.missing.request.method"
					, status = 400
					, title  = "Bad request"
					, detail = "Insufficient information. Access-Control-Request-Method request header needed."
				} );
			} );

			it( "should set an empty body on the response object when access control request is valid", function(){
				var restService        = getService();
				var resource           = { uriPattern="/some/uri/", handler="somehandler", tokens=[], verbs={ GET="testGetMethod", PUT="put", DELETE="delete" } };
				var response           = new preside.system.services.rest.PresideRestResponse();
				var mockRequestContext = getMockRequestContext();
				var uri                = "/some/test/304958/"

				response.setData( { test=true } );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Origin", default="" ).$results( "https://mysite.com" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Method", default="" ).$results( "PUT" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Headers", default="" ).$results( "" );
				restService.$( "isCorsRequestAllowed", true );

				restService.processOptionsRequest( resource=resource, response=response, requestContext=mockRequestContext, uri=uri );

				expect( response.getData() ).toBeNull();
			} );

			it( "should set a 'plain' renderer on the response object when access control request is valid", function(){
				var restService        = getService();
				var resource           = { uriPattern="/some/uri/", handler="somehandler", tokens=[], verbs={ GET="testGetMethod", PUT="put", DELETE="delete" } };
				var response           = new preside.system.services.rest.PresideRestResponse();
				var mockRequestContext = getMockRequestContext();
				var uri                = "/some/test/304958/"

				response.setData( { test=true } );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Origin", default="" ).$results( "https://mysite.com" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Method", default="" ).$results( "PUT" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Headers", default="" ).$results( "" );
				restService.$( "isCorsRequestAllowed", true );

				restService.processOptionsRequest( resource=resource, response=response, requestContext=mockRequestContext, uri=uri );

				expect( response.getRenderer() ).toBe( "plain" );
			} );

			it( "should set 'Access-Control-Allow-Methods' header on the response object to the same value as the 'Access-Control-Request-Method' header if supplied and supported by the resource", function(){
				var restService        = getService();
				var resource           = { uriPattern="/some/uri/", handler="somehandler", tokens=[], verbs={ GET="testGetMethod", PUT="put", DELETE="delete" } };
				var response           = new preside.system.services.rest.PresideRestResponse();
				var mockRequestContext = getMockRequestContext();
				var uri                = "/some/test/304958/"

				mockRequestContext.$( "getHttpHeader" ).$args( header="Origin", default="" ).$results( "https://mysite.com" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Method", default="" ).$results( "PUT" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Headers", default="" ).$results( "" );
				restService.$( "isCorsRequestAllowed", true );

				restService.processOptionsRequest( resource=resource, response=response, requestContext=mockRequestContext, uri=uri );

				var headers = response.getHeaders();

				expect( headers[ "Access-Control-Allow-Methods" ] ?: "" ).toBe( "PUT" );
			} );

			it( "should set 'Access-Control-Allow-Origin' response header to requesting domain when 'Origin' header supplied and CORS request is allowed", function(){
				var restService        = getService();
				var resource           = { uriPattern="/some/uri/", handler="somehandler", tokens=[], verbs={ GET="testGetMethod", PUT="put", DELETE="delete" } };
				var response           = new preside.system.services.rest.PresideRestResponse();
				var mockRequestContext = getMockRequestContext();
				var uri                = "/some/test/304958/";
				var origin             = "https://foobar.com";

				mockRequestContext.$( "getHttpHeader" ).$args( header="Origin", default="" ).$results( origin );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Method", default="" ).$results( "PUT" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Headers", default="" ).$results( "" );
				restService.$( "isCorsRequestAllowed" ).$args( origin=origin, uri=uri ).$results( true );

				restService.processOptionsRequest(
					  resource       = resource
					, response       = response
					, requestContext = mockRequestContext
					, uri            = uri
				);

				var headers = response.getHeaders();

				expect( headers[ "Access-Control-Allow-Origin" ] ?: "" ).toBe( origin );
			} );

			it( "should set status of 200 OK on the response when accepted", function(){
				var restService        = getService();
				var resource           = { uriPattern="/some/uri/", handler="somehandler", tokens=[], verbs={ GET="testGetMethod", PUT="put", POST="post" } };
				var response           = new preside.system.services.rest.PresideRestResponse();
				var mockRequestContext = getMockRequestContext();
				var uri                = "/some/test/304958/";
				var origin             = "https://foobar.com";

				mockRequestContext.$( "getHttpHeader" ).$args( header="Origin", default="" ).$results( origin );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Method", default="" ).$results( "PUT" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Headers", default="" ).$results( "" );
				restService.$( "isCorsRequestAllowed" ).$args( origin=origin, uri=uri ).$results( true );

				restService.processOptionsRequest(
					  resource       = resource
					, response       = response
					, requestContext = mockRequestContext
					, uri            = uri
				);

				expect( response.getStatusCode() ).toBe( 200 );
				expect( response.getStatusText() ).toBe( "OK" );
			} );

			it( "should set empty 'Access-Control-Allow-Headers' response header when 'Access-Control-Request-Headers' is empty or does not exist", function(){
				var restService        = getService();
				var resource           = { uriPattern="/some/uri/", handler="somehandler", tokens=[], verbs={ GET="testGetMethod", PUT="put", DELETE="delete" } };
				var response           = new preside.system.services.rest.PresideRestResponse();
				var mockRequestContext = getMockRequestContext();
				var uri                = "/some/test/304958/";
				var origin             = "https://foobar.com";

				mockRequestContext.$( "getHttpHeader" ).$args( header="Origin", default="" ).$results( origin );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Method", default="" ).$results( "PUT" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Headers", default="" ).$results( "" );
				restService.$( "isCorsRequestAllowed" ).$args( origin=origin, uri=uri ).$results( true );

				restService.processOptionsRequest(
					  resource       = resource
					, response       = response
					, requestContext = mockRequestContext
					, uri            = uri
				);

				var headers = response.getHeaders();

				expect( headers.keyExists( "Access-Control-Allow-Headers" ) ).toBeTrue();
				expect( headers[ "Access-Control-Allow-Headers" ] ).toBe( "" );
			} );

			it( "should set 'Access-Control-Allow-Headers' response header to the value of 'Access-Control-Request-Headers' request header when accepted", function(){
				var restService        = getService();
				var resource           = { uriPattern="/some/uri/", handler="somehandler", tokens=[], verbs={ GET="testGetMethod", PUT="put", DELETE="delete" } };
				var response           = new preside.system.services.rest.PresideRestResponse();
				var mockRequestContext = getMockRequestContext();
				var uri                = "/some/test/304958/";
				var origin             = "https://foobar.com";
				var requestHeaders     = "X-Blah,Me-Blah";

				mockRequestContext.$( "getHttpHeader" ).$args( header="Origin", default="" ).$results( origin );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Method", default="" ).$results( "PUT" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Headers", default="" ).$results( requestHeaders );
				restService.$( "isCorsRequestAllowed" ).$args( origin=origin, uri=uri ).$results( true );

				restService.processOptionsRequest(
					  resource       = resource
					, response       = response
					, requestContext = mockRequestContext
					, uri            = uri
				);

				var headers = response.getHeaders();

				expect( headers.keyExists( "Access-Control-Allow-Headers" ) ).toBeTrue();
				expect( headers[ "Access-Control-Allow-Headers" ] ).toBe( requestHeaders );
			} );

			it( "should set no 'Access-Control' response headers when CORS requests not allowed", function(){
				var restService        = getService();
				var resource           = { uriPattern="/some/uri/", handler="somehandler", tokens=[], verbs={ GET="testGetMethod", PUT="put", DELETE="delete" } };
				var response           = new preside.system.services.rest.PresideRestResponse();
				var mockRequestContext = getMockRequestContext();
				var uri                = "/some/test/304958/";
				var origin             = "https://foobar.com";

				mockRequestContext.$( "getHttpHeader" ).$args( header="Origin", default="" ).$results( origin );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Method", default="" ).$results( "PUT" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Headers", default="" ).$results( "" );
				restService.$( "isCorsRequestAllowed" ).$args( origin=origin, uri=uri ).$results( false );

				restService.processOptionsRequest(
					  resource       = resource
					, response       = response
					, requestContext = mockRequestContext
					, uri            = uri
				);

				var headers = response.getHeaders() ?: {};

				expect( headers.keyExists( "Access-Control-Allow-Origin" ) ).toBeFalse();
				expect( headers.keyExists( "Access-Control-Allow-Methods" ) ).toBeFalse();
				expect( headers.keyExists( "Access-Control-Allow-Headers" ) ).toBeFalse();
			} );

			it( "should set no 'Access-Control' response headers when CORS allowed but method not supported by the resource", function(){
				var restService        = getService();
				var resource           = { uriPattern="/some/uri/", handler="somehandler", tokens=[], verbs={ GET="testGetMethod", PUT="put", POST="post" } };
				var response           = new preside.system.services.rest.PresideRestResponse();
				var mockRequestContext = getMockRequestContext();
				var uri                = "/some/test/304958/";
				var origin             = "https://foobar.com";

				mockRequestContext.$( "getHttpHeader" ).$args( header="Origin", default="" ).$results( origin );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Method", default="" ).$results( "DELETE" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Headers", default="" ).$results( "" );
				restService.$( "isCorsRequestAllowed" ).$args( origin=origin, uri=uri ).$results( true );

				restService.processOptionsRequest(
					  resource       = resource
					, response       = response
					, requestContext = mockRequestContext
					, uri            = uri
				);

				var headers = response.getHeaders() ?: {};

				expect( headers.keyExists( "Access-Control-Allow-Origin" ) ).toBeFalse();
				expect( headers.keyExists( "Access-Control-Allow-Methods" ) ).toBeFalse();
				expect( headers.keyExists( "Access-Control-Allow-Headers" ) ).toBeFalse();
			} );

			it( "should set a 403 Forbidden status when CORS requests not allowed", function(){
				var restService        = getService();
				var resource           = { uriPattern="/some/uri/", handler="somehandler", tokens=[], verbs={ GET="testGetMethod", PUT="put", DELETE="delete" } };
				var response           = new preside.system.services.rest.PresideRestResponse();
				var mockRequestContext = getMockRequestContext();
				var uri                = "/some/test/304958/";

				mockRequestContext.$( "getHttpHeader" ).$args( header="Origin", default="" ).$results( "http://mysite.com" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Method", default="" ).$results( "DELETE" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Headers", default="" ).$results( "" );
				restService.$( "isCorsRequestAllowed", false );

				restService.processOptionsRequest(
					  resource       = resource
					, response       = response
					, requestContext = mockRequestContext
					, uri            = uri
				);

				expect( response.getStatusCode() ).toBe( 403 );
				expect( response.getStatusText() ).toBe( "Forbidden" );
				expect( response.getRenderer() ).toBe( "json" );
				expect( response.getData() ).toBe( {
					  type   = "rest.cors.forbidden"
					, status = 403
					, title  = "Forbidden"
					, detail = "This CORS request is not allowed. Either CORS is disabled for this resource, or the Origin [http://mysite.com] has not been whitelisted."
				} );
			} );

			it( "should set a 403 Forbidden status when CORS requests allowed, but request method is not allowed", function(){
				var restService        = getService();
				var resource           = { uriPattern="/some/uri/", handler="somehandler", tokens=[], verbs={ GET="testGetMethod", PUT="put", DELETE="delete" } };
				var response           = new preside.system.services.rest.PresideRestResponse();
				var mockRequestContext = getMockRequestContext();
				var uri                = "/some/test/304958/";

				mockRequestContext.$( "getHttpHeader" ).$args( header="Origin", default="" ).$results( "http://mysite.com" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Method", default="" ).$results( "POST" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Headers", default="" ).$results( "" );
				restService.$( "isCorsRequestAllowed", true );

				restService.processOptionsRequest(
					  resource       = resource
					, response       = response
					, requestContext = mockRequestContext
					, uri            = uri
				);

				expect( response.getStatusCode() ).toBe( 403 );
				expect( response.getStatusText() ).toBe( "Forbidden" );
				expect( response.getRenderer() ).toBe( "json" );
				expect( response.getData() ).toBe( {
					  type   = "rest.cors.forbidden"
					, status = 403
					, title  = "Forbidden"
					, detail = "This CORS request is not allowed. The resource at [/some/test/304958/] does not support the [POST] method."
				} );
			} );
		} );

		describe( "processResponse()", function(){
			it( "should call renderData on the request context", function(){
				var restService        = getService();
				var mockRequestContext = getMockRequestContext();
				var response           = new preside.system.services.rest.PresideRestResponse();

				restService.processResponse( response, mockRequestContext, "/test", "GET" );

				expect( mockRequestContext.$callLog().renderData.len() ).toBe( 1 );
			} );

			it( "should pass the response renderer to the 'type' argument in renderData", function(){
				var restService        = getService();
				var mockRequestContext = getMockRequestContext();
				var response           = new preside.system.services.rest.PresideRestResponse();

				response.setRenderer( "jsonp" );
				restService.processResponse( response, mockRequestContext, "/test", "GET" );

				var renderDataArgs = mockRequestContext.$callLog().renderData[1];
				expect( renderDataArgs.keyExists( "type" ) ).toBeTrue();
				expect( renderDataArgs.type ).toBe( "jsonp" );
			} );

			it( "should pass the response mime type to the 'contenttype' argument in renderData", function(){
				var restService        = getService();
				var mockRequestContext = getMockRequestContext();
				var response           = new preside.system.services.rest.PresideRestResponse();

				response.setMimeType( "text/plain" );
				restService.processResponse( response, mockRequestContext, "/test", "GET" );

				var renderDataArgs = mockRequestContext.$callLog().renderData[1];
				expect( renderDataArgs.keyExists( "contentType" ) ).toBeTrue();
				expect( renderDataArgs.contentType ).toBe( "text/plain" );
			} );

			it( "should pass the response status code to the 'statusCode' argument in renderData", function(){
				var restService        = getService();
				var mockRequestContext = getMockRequestContext();
				var response           = new preside.system.services.rest.PresideRestResponse();

				response.setStatusCode( 451 );
				restService.processResponse( response, mockRequestContext, "/test", "GET" );

				var renderDataArgs = mockRequestContext.$callLog().renderData[1];
				expect( renderDataArgs.keyExists( "statusCode" ) ).toBeTrue();
				expect( renderDataArgs.statusCode ).toBe( 451 );
			} );

			it( "should pass the response status text to the 'statusText' argument in renderData", function(){
				var restService        = getService();
				var mockRequestContext = getMockRequestContext();
				var response           = new preside.system.services.rest.PresideRestResponse();

				response.setStatusText( "This content has been censored and cannot therefor be shown" );
				restService.processResponse( response, mockRequestContext, "/test", "GET" );

				var renderDataArgs = mockRequestContext.$callLog().renderData[1];
				expect( renderDataArgs.keyExists( "statusText" ) ).toBeTrue();
				expect( renderDataArgs.statusText ).toBe( "This content has been censored and cannot therefor be shown" );
			} );

			it( "should pass the response data to the 'data' argument in renderData", function(){
				var restService        = getService();
				var mockRequestContext = getMockRequestContext();
				var response           = new preside.system.services.rest.PresideRestResponse();

				response.setData( { test="data" } );
				restService.processResponse( response, mockRequestContext, "/test", "GET" );

				var renderDataArgs = mockRequestContext.$callLog().renderData[1];
				expect( renderDataArgs.keyExists( "data" ) ).toBeTrue();
				expect( renderDataArgs.data ).toBe( { test="data" } );
			} );

			it( "should pass an empty string to the renderData 'data' argument, when the data in the response object is NULL", function(){
				var restService        = getService();
				var mockRequestContext = getMockRequestContext();
				var response           = new preside.system.services.rest.PresideRestResponse();

				response.noData();
				restService.processResponse( response, mockRequestContext, "/test", "GET" );

				var renderDataArgs = mockRequestContext.$callLog().renderData[1];
				expect( renderDataArgs.keyExists( "data" ) ).toBeTrue();
				expect( renderDataArgs.data ).toBe( "" );
			} );

			it( "should call setHttpHeader() on the request context for each header set in the response", function(){
				var restService        = getService();
				var mockRequestContext = getMockRequestContext();
				var response           = new preside.system.services.rest.PresideRestResponse();

				response.setHeaders({
					  "X-My-Header"      = "my value"
					, "X-Another-Header" = "another value"
					, "X-good-stuff"     = "yes"
				});

				restService.processResponse( response, mockRequestContext, "/test", "GET" );

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

			it( "should set noData() on the response when the verb is HEAD", function(){
				var restService        = getService();
				var mockRequestContext = getMockRequestContext();
				var response           = new preside.system.services.rest.PresideRestResponse();

				response.setData( { test="data" } );
				restService.processResponse(
					  response       = response
					, requestContext = mockRequestContext
					, uri            = "/some/uri"
					, verb           = "HEAD"
				);

				expect( response.getData() ).toBeNull();
			} );

			it( "should set a 304 response when ETag matches supplied If-None-Match header", function(){
				var restService        = getService();
				var mockRequestContext = getMockRequestContext();
				var response           = new preside.system.services.rest.PresideRestResponse();
				var etag               = LCase( Hash( Now() ) );

				response.setData( { test="data" } );
				response.setHeader( "etag", etag );

				restService.$( "setEtag", etag );
				mockRequestContext.$( "getHttpHeader" ).$args( header="If-None-Match", default="" ).$results( etag );
				restService.processResponse(
					  response       = response
					, requestContext = mockRequestContext
					, uri            = "/some/uri"
					, verb           = "HEAD"
				);

				expect( response.getData() ).toBeNull();
				expect( response.getRenderer() ).toBe( "plain" );
				expect( response.getStatusCode() ).toBe( 304 );
				expect( response.getStatusText() ).toBe( "Not modified" );
			} );
		} );

		describe( "getEtag", function(){
			it( "should calculate etag based on an MD5 hash of the serialized data", function(){
				var restService  = getService();
				var response     = new preside.system.services.rest.PresideRestResponse();
				var data         = { this="is some test data", which="is", very=true };
				var expectedEtag = LCase( Hash( Serialize( data ) ) );

				response.setData( data );

				expect( restService.getEtag( response ) ).toBe( expectedEtag );
			} );

			it( "should return an empty string when there is no data in the response", function(){
				var restService  = getService();
				var response     = new preside.system.services.rest.PresideRestResponse();

				response.noData();

				expect( restService.getEtag( response ) ).toBe( "" );
			} );
		} );

		describe( "setEtag", function(){
			it( "should set ETAG in the response when there is data", function(){
				var restService  = getService();
				var response     = new preside.system.services.rest.PresideRestResponse();
				var dummyEtag    = LCase( Hash( Now() ) );

				restService.$( "getEtag" ).$args( response ).$results( dummyEtag );
				restService.setEtag( response );

				var headers = response.getHeaders();
				expect( headers.etag ?: "" ).toBe( dummyEtag );
			} );

			it( "should not set ETAG in the response when the etag is empty", function(){
				var restService  = getService();
				var response     = new preside.system.services.rest.PresideRestResponse();

				restService.$( "getEtag" ).$args( response ).$results( "" );
				restService.setEtag( response );

				var headers = response.getHeaders() ?: {};
				expect( headers.keyExists( "etag" ) ).toBeFalse();
			} );
		} );

		describe( "getVerb()", function(){
			it( "should return value of X-HTTP-Method-Override header when supplied and use HTTP method used in the request otherwise", function(){
				var restService        = getService();
				var mockRequestContext = getMockRequestContext();
				var mockHttpMethod     = CreateUUId();
				var mockHttpHeader     = CreateUUId();

				mockRequestContext.$( "getHttpMethod", mockHttpMethod );
				mockRequestContext.$( "getHttpHeader" ).$args(
					  header  = "X-HTTP-Method-Override"
					, default = mockHttpMethod
				).$results( mockHttpHeader );

				expect( restService.getVerb( mockRequestContext )  ).toBe( mockHttpHeader );
			} );
		} );

		describe( "isCorsRequestAllowed()", function(){
			it( "should return true when the result of getSetting call to config wrapper is true", function(){
				var restService = getService();
				var uri         = "/test/some/api";
				var api         = "/test/some/";

				restService.$( "getApiForUri", api );
				mockConfigWrapper.$( "getSetting" ).$args(
					  name         = "corsEnabled"
					, api          = api
				).$results( true );

				expect( restService.isCorsRequestAllowed( uri ) ).toBeTrue();
			} );

			it( "should return false when the result of getSetting call to config wrapper is false", function(){
				var restService = getService();
				var uri         = "/test/some/api";
				var api         = "/test/some/";

				restService.$( "getApiForUri", api );
				mockConfigWrapper.$( "getSetting" ).$args(
					  name         = "corsEnabled"
					, api          = api
				).$results( false );

				expect( restService.isCorsRequestAllowed( uri ) ).toBeFalse();
			} );

			it( "should return false when the result of getSetting call to config wrapper is not a boolean value", function(){
				var restService = getService();
				var uri         = "/test/some/api";
				var api         = "/test/some/";

				restService.$( "getApiForUri", api );
				mockConfigWrapper.$( "getSetting" ).$args(
					  name         = "corsEnabled"
					, api          = api
				).$results( "" );

				expect( restService.isCorsRequestAllowed( uri ) ).toBeFalse();
			} );
		} );

	}

	private any function getService( ) {
		variables.mockController    = createStub();
		variables.mockConfigWrapper = createEmptyMock( "preside.system.services.rest.PresideRestConfigurationWrapper" );

		var restService = createMock( object=new preside.system.services.rest.PresideRestService(
			  controller           = mockController
			, resourceDirectories  = [ "/resources/rest/dir1", "/resources/rest/dir2" ]
			, configurationWrapper = mockConfigWrapper
		) );

		restService.$( "_announceInterception" );
		restService.$( "$raiseError" );

		return restService;
	}

	private any function getMockRequestContext() {
		var rc = createEmptyMock( "coldbox.system.web.context.RequestContext" );

		rc.$( "getHttpMethod", "get" );
		rc.$( "setHttpHeader", rc );
		rc.$( "getHttpHeader", "" );
		rc.$( "renderData", rc );
		rc.$( "getInstanceIdForComparison", CreateUUId() );

		return rc;
	}

}