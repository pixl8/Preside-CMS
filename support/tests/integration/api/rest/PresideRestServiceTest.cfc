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
				var result = restService.getResourceForUri( api="/api1", resourcePath="/test/my-pattern/#CreateUUId()#/" );
				expect( result ).toBe( {
					  handler    = "api1.ResourceX"
					, tokens     = [ "pattern", "id" ]
					, uriPattern = "^/test/(.*?)/(.*?)/$"
					, verbs      = { post="post", get="get", delete="delete", put="putDataTest" }
					, requiredParameters = { delete=[], get=[], put=[] }
					, parameterTypes = { delete={}, get={}, put={} }
				} );
			} );

			it( "should return an empty struct when no resource is found", function(){
				var restService = getService();

				expect( restService.getResourceForUri( api="/whatever", resourcePath="/this/is/#CreateUUId()#/" ) ).toBe( {} );
			} );

		} );

		describe( "extractTokensFromUri", function(){
			it( "should extract tokens from a resource URI from the actual incoming URI as a struct", function(){
				var restService = getService();
				var id          = CreateUUId();
				var object      = "myObject";
				var restRequest = getRestRequest( uri="/object/#object#/#id#/", resource={ uriPattern="/object/(.*?)/(.*?)/", tokens=[ "object", "id" ] } );

				var tokens = restService.extractTokensFromUri( restRequest );
				expect( tokens ).toBe( { object=object, id=id } );
			} );
		} );

		describe( "onRestRequest", function(){

			it( "should announce an onRestRequest interception point", function(){
				var restService        = getService();
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest();
				var mockRequestContext = getMockRequestContext();

				restService.$( "createRestResponse", restResponse );
				restService.$( "createRestRequest" , restRequest  );
				restService.$( "processRequest"     );
				restService.$( "processResponse"    );

				restService.onRestRequest( "/blah", mockRequestContext );

				var log = restService.$callLog()._announceInterception;
				expect( log.len() > 0 ).toBe( true );
				expect( log[2] ).toBe([ "onRestRequest", { restRequest=restRequest, restResponse=restResponse } ]);
			} );

			it( "it should call processRequest to handle the request", function(){
				var restService        = getService();
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest();
				var mockRequestContext = getMockRequestContext();

				restService.$( "createRestResponse", restResponse );
				restService.$( "createRestRequest" , restRequest  );
				restService.$( "processRequest"  );
				restService.$( "processResponse" );

				restService.onRestRequest( "/blah", mockRequestContext );

				var callLog = restService.$callLog().processRequest;

				expect( callLog.len() ).toBe( 1 );
				expect( callLog[1].restRequest ).toBe( restRequest );
				expect( callLog[1].restResponse ).toBe( restResponse );
				expect( callLog[1].requestContext.getInstanceIdForComparison() ).toBe( mockRequestContext.getInstanceIdForComparison() );
			} );

			it( "should not call processRequest when request is marked as finished (e.g. by an interceptor)", function(){
				var restService        = getService();
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest( finished=true );
				var mockRequestContext = getMockRequestContext();

				restService.$( "createRestResponse", restResponse );
				restService.$( "createRestRequest" , restRequest  );
				restService.$( "processRequest"  );
				restService.$( "processResponse" );

				restService.onRestRequest( "/blah", mockRequestContext );

				var callLog = restService.$callLog().processRequest;

				expect( callLog.len() ).toBe( 0 );
			} );

			it( "it should call processResponse to render the result", function(){
				var restService        = getService();
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest();
				var mockRequestContext = getMockRequestContext();

				restService.$( "createRestResponse", restResponse );
				restService.$( "createRestRequest" , restRequest  );
				restService.$( "processRequest"     );
				restService.$( "processResponse"    );

				restService.onRestRequest( "/blah", mockRequestContext );

				var callLog = restService.$callLog().processResponse;

				expect( callLog.len() ).toBe( 1 );
				expect( callLog[1].restRequest ).toBe( restRequest );
				expect( callLog[1].restResponse ).toBe( restResponse );
				expect( callLog[1].requestContext.getInstanceIdForComparison() ).toBe( mockRequestContext.getInstanceIdForComparison() );
			} );

			it( "should authenticate requests", function(){
				var restService        = getService();
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest();
				var mockRequestContext = getMockRequestContext();

				restService.$( "createRestResponse", restResponse );
				restService.$( "createRestRequest" , restRequest  );
				restService.$( "processRequest"  );
				restService.$( "processResponse" );

				restService.onRestRequest( "/blah", mockRequestContext );

				var callLog = restService.$callLog().authenticateRequest;

				expect( callLog.len() ).toBe( 1 );
				expect( callLog[1].restRequest ).toBe( restRequest );
				expect( callLog[1].restResponse ).toBe( restResponse );
				expect( callLog[1].requestContext.getInstanceIdForComparison() ).toBe( mockRequestContext.getInstanceIdForComparison() );
			} );

			it( "should NOT authenticate OPTIONS requests", function(){
				var restService        = getService();
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest( verb="OPTIONS" );
				var mockRequestContext = getMockRequestContext();

				restService.$( "createRestResponse", restResponse );
				restService.$( "createRestRequest" , restRequest  );
				restService.$( "processRequest"  );
				restService.$( "processResponse" );

				restService.onRestRequest( "/blah", mockRequestContext );

				var callLog = restService.$callLog().authenticateRequest;

				expect( callLog.len() ).toBe( 0 );
			} );


		} );

		describe( "processRequest", function(){
			it( "should set error on the response when no resource handler exists for the request", function(){
				var restService        = getService();
				var restRequest        = getRestRequest( resource={}, uri="/some/uri/23" );
				var restResponse       = CreateMock( object=getRestResponse() );
				var mockRequestContext = getMockRequestContext();

				restResponse.$( "setError" );

				restService.processRequest( restRequest=restRequest, restResponse=restResponse, requestContext=mockRequestContext );

				var log = restResponse.$callLog().setError;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( {
					  errorCode = 404
					, title     = "REST API Resource not found"
					, type      = "rest.resource.not.found"
					, message   = "The requested resource, [/some/uri/23], did not match any resources in the Preside REST API"
				} );

			} );

			it( "should set error on the response when resource handler exists, but not for the current HTTP VERB in use", function(){
				var restService        = getService();
				var restResponse       = CreateMock( object=getRestResponse() );
				var mockRequestContext = getMockRequestContext();
				var restRequest        = getRestRequest( resource={
					  handler    = "myResource"
					, tokens     = [ "whatever", "thisisjust", "atest" ]
					, uriPattern = "/test/(.*?)/(.*?)/"
					, verbs      = { post="post", get="get", delete="delete" }
				}, uri="/some/uri/23", verb="PUT" );

				restResponse.$( "setError" );

				restService.processRequest( restRequest=restRequest, restResponse=restResponse, requestContext=mockRequestContext );

				var log = restResponse.$callLog().setError;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( {
					  errorCode = 405
					, title     = "REST API Method not supported"
					, type      = "rest.method.unsupported"
					, message   = "The requested resource, [/some/uri/23], does not support the [PUT] method"
				} );
			} );

			it( "should not set error when verb is HEAD and no explicit HEAD handler exists for the resource", function(){
				var restService        = getService();
				var mockRequestContext = getMockRequestContext();
				var mockResponse       = createEmptyMock( "preside.system.services.rest.PresideRestResponse" );
				var restRequest        = getRestRequest( resource={
					  handler    = "myResource"
					, tokens     = [ "whatever", "thisisjust", "atest" ]
					, uriPattern = "/test/(.*?)/(.*?)/"
					, verbs      = { post="post", get="get", delete="delete" }
				}, uri="/some/uri/23", verb="HEAD" );

				restService.$( "invokeRestResourceHandler" );

				mockResponse.$( "setError" );

				restService.processRequest(
					  restRequest    = restRequest
					, restResponse   = mockResponse
					, requestContext = mockRequestContext
				);

				var callLog = mockResponse.$callLog().setError;

				expect( callLog.len() ).toBe( 0 );
			} );

			it( "should not set error when verb is OPTIONS and no explicit OPTIONS handler exists for the resource", function(){
				var restService        = getService();
				var mockRequestContext = getMockRequestContext();
				var mockResponse       = createEmptyMock( "preside.system.services.rest.PresideRestResponse" );
				var restRequest        = getRestRequest( resource={
					  handler    = "myResource"
					, tokens     = [ "whatever", "thisisjust", "atest" ]
					, uriPattern = "/test/(.*?)/(.*?)/"
					, verbs      = { post="post", get="get", delete="delete" }
				}, uri="/some/uri/23", verb="OPTIONS" );

				restService.$( "invokeRestResourceHandler" );
				restService.$( "processOptionsRequest" );

				mockResponse.$( "setError" );

				restService.processRequest(
					  restRequest    = restRequest
					, restResponse   = mockResponse
					, requestContext = mockRequestContext
				);

				var callLog = mockResponse.$callLog().setError;

				expect( callLog.len() ).toBe( 0 );
			} );

			it( "should process OPTIONS requests with using the processOptionsRequest method if no specific OPTIONS method supplied by the resource", function(){
				var restService        = getService();
				var mockRequestContext = getMockRequestContext();
				var mockResponse       = createEmptyMock( "preside.system.services.rest.PresideRestResponse" );
				var restRequest        = getRestRequest( resource={
					  handler    = "myResource"
					, tokens     = [ "whatever", "thisisjust", "atest" ]
					, uriPattern = "/test/(.*?)/(.*?)/"
					, verbs      = { post="post", get="get", delete="delete" }
				}, uri="/some/uri/23", verb="OPTIONS" );

				restService.$( "invokeRestResourceHandler" );
				restService.$( "processOptionsRequest" );

				mockResponse.$( "setError" );

				restService.processRequest(
					  restRequest    = restRequest
					, restResponse   = mockResponse
					, requestContext = mockRequestContext
				);

				var callLog = restService.$callLog();

				expect( callLog.processOptionsRequest.len() ).toBe( 1 );
				expect( callLog.invokeRestResourceHandler.len() ).toBe( 0 );
			} );

			it( "should process OPTIONS requests using the supplied OPTIONS method of the resource when defined in the resource", function(){
				var restService        = getService();
				var mockRequestContext = getMockRequestContext();
				var mockResponse       = createEmptyMock( "preside.system.services.rest.PresideRestResponse" );
				var restRequest        = getRestRequest( resource={
					  handler    = "myResource"
					, tokens     = [ "whatever", "thisisjust", "atest" ]
					, uriPattern = "/test/(.*?)/(.*?)/"
					, verbs      = { post="post", get="get", delete="delete", options="options" }
				}, uri="/some/uri/23", verb="OPTIONS" );

				restService.$( "invokeRestResourceHandler" );
				restService.$( "processOptionsRequest" );

				mockResponse.$( "setError" );

				restService.processRequest(
					  restRequest    = restRequest
					, restResponse   = mockResponse
					, requestContext = mockRequestContext
				);

				var callLog = restService.$callLog();
				var callLog = restService.$callLog();

				expect( callLog.processOptionsRequest.len() ).toBe( 0 );
				expect( callLog.invokeRestResourceHandler.len() ).toBe( 1 );
			} );
		} );

		describe( "invokeRestResourceHandler", function(){
			it( "it should call the matched coldbox handler for the given request and http method", function(){
				var restService        = getService();
				var restResponse       = CreateMock( object=getRestResponse() );
				var mockRequestContext = getMockRequestContext();
				var mockTokens         = { test=CreateUUId(), random=true };
				var rc                 = { anotherTest=true };
				var restRequest        = getRestRequest( resource={
					  uriPattern="blah"
					, tokens=["blah"]
					, verbs={ PUT="putDataTest" }
					, handler="myResource"
				}, uri="/some/uri/23", verb="PUT" );
				var expectedArgs = Duplicate( mockTokens );

				expectedArgs.append( rc );
				expectedArgs.restRequest = restRequest;
				expectedArgs.restResponse = restResponse;

				restService.$( "extractTokensFromUri"   ).$args( restRequest ).$results( mockTokens );
				mockController.$( "runEvent" );
				mockRequestContext.$( "getCollectionWithoutSystemVars", rc );

				restService.invokeRestResourceHandler( restRequest=restRequest, restResponse=restResponse, requestContext=mockRequestContext  );

				var callLog = mockController.$callLog().runEvent;

				expect( callLog.len() ).toBe( 1 );
				expect( callLog[1].event ).toBe( "rest-apis.myResource.putDataTest" );
				expect( callLog[1].prePostExempt ).toBe( false );
				expect( callLog[1].private ).toBe( true  );
				expect( callLog[1].eventArguments ).toBe( expectedArgs );
			} );

			it( "should call the GET method of a resource when verb is HEAD and no specific HEAD method exists", function(){
				var restService        = getService();
				var restResponse       = CreateMock( object=getRestResponse() );
				var mockRequestContext = getMockRequestContext();
				var mockTokens         = { test=CreateUUId(), random=true };
				var rc                 = { anotherTest=true };
				var restRequest        = getRestRequest( resource={
					  uriPattern="blah"
					, tokens=["blah"]
					, verbs={ GET="testGetMethod" }
					, handler="somehandler"
				}, uri="/some/uri/23", verb="HEAD" );
				var expectedArgs = Duplicate( mockTokens );

				expectedArgs.append( rc );
				expectedArgs.restRequest = restRequest;
				expectedArgs.restResponse = restResponse;

				restService.$( "extractTokensFromUri"   ).$args( restRequest ).$results( mockTokens );
				mockController.$( "runEvent" );
				mockRequestContext.$( "getCollectionWithoutSystemVars", rc );

				restService.invokeRestResourceHandler( restRequest=restRequest, restResponse=restResponse, requestContext=mockRequestContext  );

				var callLog = mockController.$callLog().runEvent;

				expect( callLog.len() ).toBe( 1 );
				expect( callLog[1].event ).toBe( "rest-apis.somehandler.testGetMethod" );
			} );
		} );

		describe( "processOptionsRequest()", function(){
			it( "should set a 400 error when 'Origin' request header is missing", function(){
				var restService        = getService();
				var resource           = { uriPattern="/some/uri/", handler="somehandler", tokens=[], verbs={ GET="testGetMethod", PUT="put", DELETE="delete" } };
				var uri                = "/some/test/304958/"
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest( resource=resource, uri=uri, verb="OPTIONS" );
				var mockRequestContext = getMockRequestContext();

				restResponse.setData( { test=true } );

				restService.processOptionsRequest(
					  restRequest    = restRequest
					, restResponse   = restResponse
					, requestContext = mockRequestContext
				);

				expect( restResponse.getStatusCode() ).toBe( 400 );
				expect( restResponse.getStatusText() ).toBe( "Bad request" );
				expect( restResponse.getRenderer() ).toBe( "json" );
				expect( restResponse.getData() ).toBe( {
					  type   = "rest.options.missing.origin"
					, status = 400
					, title  = "Bad request"
					, detail = "Insufficient information. Origin request header needed."
				} );
			} );

			it( "should set a 400 error when 'Access-Control-Request-Method' request header is missing", function(){
				var restService        = getService();
				var resource           = { uriPattern="/some/uri/", handler="somehandler", tokens=[], verbs={ GET="testGetMethod", PUT="put", DELETE="delete" } };
				var uri                = "/some/test/304958/"
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest( resource=resource, uri=uri, verb="OPTIONS" );
				var mockRequestContext = getMockRequestContext();

				restResponse.setData( { test=true } );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Origin", default="" ).$results( "https://mysite.com" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Method", default="" ).$results( "" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Headers", default="" ).$results( "" );

				restService.processOptionsRequest(
					  restRequest    = restRequest
					, restResponse   = restResponse
					, requestContext = mockRequestContext
				);

				expect( restResponse.getStatusCode() ).toBe( 400 );
				expect( restResponse.getStatusText() ).toBe( "Bad request" );
				expect( restResponse.getRenderer() ).toBe( "json" );
				expect( restResponse.getData() ).toBe( {
					  type   = "rest.options.missing.request.method"
					, status = 400
					, title  = "Bad request"
					, detail = "Insufficient information. Access-Control-Request-Method request header needed."
				} );
			} );

			it( "should set an empty body on the response object when access control request is valid", function(){
				var restService        = getService();
				var resource           = { uriPattern="/some/uri/", handler="somehandler", tokens=[], verbs={ GET="testGetMethod", PUT="put", DELETE="delete" } };
				var uri                = "/some/test/304958/";
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest( resource=resource, uri=uri, verb="OPTIONS" );
				var mockRequestContext = getMockRequestContext();

				restResponse.setData( { test=true } );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Origin", default="" ).$results( "https://mysite.com" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Method", default="" ).$results( "PUT" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Headers", default="" ).$results( "" );
				restService.$( "isCorsRequestAllowed", true );

				restService.processOptionsRequest(
					  restRequest    = restRequest
					, restResponse   = restResponse
					, requestContext = mockRequestContext
				);

				expect( restResponse.getData() ).toBeNull();
			} );

			it( "should set a 'plain' renderer on the response object when access control request is valid", function(){
				var restService        = getService();
				var resource           = { uriPattern="/some/uri/", handler="somehandler", tokens=[], verbs={ GET="testGetMethod", PUT="put", DELETE="delete" } };
				var uri                = "/some/test/304958/"
				var mockRequestContext = getMockRequestContext();
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest( resource=resource, uri=uri, verb="OPTIONS" );

				restResponse.setData( { test=true } );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Origin", default="" ).$results( "https://mysite.com" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Method", default="" ).$results( "PUT" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Headers", default="" ).$results( "" );
				restService.$( "isCorsRequestAllowed", true );

				restService.processOptionsRequest(
					  restRequest    = restRequest
					, restResponse   = restResponse
					, requestContext = mockRequestContext
				);

				expect( restResponse.getRenderer() ).toBe( "plain" );
			} );

			it( "should set 'Access-Control-Allow-Methods' header on the response object to the same value as the 'Access-Control-Request-Method' header if supplied and supported by the resource", function(){
				var restService        = getService();
				var resource           = { uriPattern="/some/uri/", handler="somehandler", tokens=[], verbs={ GET="testGetMethod", PUT="put", DELETE="delete" } };
				var uri                = "/some/test/304958/";
				var mockRequestContext = getMockRequestContext();
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest( resource=resource, uri=uri, verb="OPTIONS" );

				mockRequestContext.$( "getHttpHeader" ).$args( header="Origin", default="" ).$results( "https://mysite.com" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Method", default="" ).$results( "PUT" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Headers", default="" ).$results( "" );
				restService.$( "isCorsRequestAllowed", true );

				restService.processOptionsRequest(
					  restRequest    = restRequest
					, restResponse   = restResponse
					, requestContext = mockRequestContext
				);

				var headers = restResponse.getHeaders();

				expect( headers[ "Access-Control-Allow-Methods" ] ?: "" ).toBe( "PUT" );
			} );

			it( "should set 'Access-Control-Allow-Origin' response header to requesting domain when 'Origin' header supplied and CORS request is allowed", function(){
				var restService        = getService();
				var resource           = { uriPattern="/some/uri/", handler="somehandler", tokens=[], verbs={ GET="testGetMethod", PUT="put", DELETE="delete" } };
				var mockRequestContext = getMockRequestContext();
				var uri                = "/some/test/304958/";
				var api                = "/v1";
				var origin             = "https://foobar.com";
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest( resource=resource, uri=uri, verb="OPTIONS", api=api );

				mockRequestContext.$( "getHttpHeader" ).$args( header="Origin", default="" ).$results( origin );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Method", default="" ).$results( "PUT" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Headers", default="" ).$results( "" );
				restService.$( "isCorsRequestAllowed" ).$args( origin=origin, api=api ).$results( true );

				restService.processOptionsRequest(
					  restRequest    = restRequest
					, restResponse   = restResponse
					, requestContext = mockRequestContext
				);

				var headers = restResponse.getHeaders();

				expect( headers[ "Access-Control-Allow-Origin" ] ?: "" ).toBe( origin );
			} );

			it( "should set status of 200 OK on the response when accepted", function(){
				var restService        = getService();
				var resource           = { uriPattern="/some/uri/", handler="somehandler", tokens=[], verbs={ GET="testGetMethod", PUT="put", POST="post" } };
				var mockRequestContext = getMockRequestContext();
				var uri                = "/some/test/304958/";
				var api                = "/v1";
				var origin             = "https://foobar.com";
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest( resource=resource, uri=uri, verb="OPTIONS", api=api );

				mockRequestContext.$( "getHttpHeader" ).$args( header="Origin", default="" ).$results( origin );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Method", default="" ).$results( "PUT" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Headers", default="" ).$results( "" );
				restService.$( "isCorsRequestAllowed" ).$args( origin=origin, api=api ).$results( true );

				restService.processOptionsRequest(
					  restRequest    = restRequest
					, restResponse   = restResponse
					, requestContext = mockRequestContext
				);

				expect( restResponse.getStatusCode() ).toBe( 200 );
				expect( restResponse.getStatusText() ).toBe( "OK" );
			} );

			it( "should set empty 'Access-Control-Allow-Headers' response header when 'Access-Control-Request-Headers' is empty or does not exist", function(){
				var restService        = getService();
				var resource           = { uriPattern="/some/uri/", handler="somehandler", tokens=[], verbs={ GET="testGetMethod", PUT="put", DELETE="delete" } };
				var mockRequestContext = getMockRequestContext();
				var uri                = "/some/test/304958/";
				var api                = "/v1";
				var origin             = "https://foobar.com";
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest( resource=resource, uri=uri, verb="OPTIONS", api=api );

				mockRequestContext.$( "getHttpHeader" ).$args( header="Origin", default="" ).$results( origin );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Method", default="" ).$results( "PUT" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Headers", default="" ).$results( "" );
				restService.$( "isCorsRequestAllowed" ).$args( origin=origin, api=api ).$results( true );

				restService.processOptionsRequest(
					  restRequest    = restRequest
					, restResponse   = restResponse
					, requestContext = mockRequestContext
				);

				var headers = restResponse.getHeaders();

				expect( headers.keyExists( "Access-Control-Allow-Headers" ) ).toBeTrue();
				expect( headers[ "Access-Control-Allow-Headers" ] ).toBe( "" );
			} );

			it( "should set 'Access-Control-Allow-Headers' response header to the value of 'Access-Control-Request-Headers' request header when accepted", function(){
				var restService        = getService();
				var resource           = { uriPattern="/some/uri/", handler="somehandler", tokens=[], verbs={ GET="testGetMethod", PUT="put", DELETE="delete" } };
				var mockRequestContext = getMockRequestContext();
				var uri                = "/some/test/304958/";
				var api                = "/v1";
				var origin             = "https://foobar.com";
				var requestHeaders     = "X-Blah,Me-Blah";
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest( resource=resource, uri=uri, verb="OPTIONS", api=api );

				mockRequestContext.$( "getHttpHeader" ).$args( header="Origin", default="" ).$results( origin );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Method", default="" ).$results( "PUT" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Headers", default="" ).$results( requestHeaders );
				restService.$( "isCorsRequestAllowed" ).$args( origin=origin, api=api ).$results( true );

				restService.processOptionsRequest(
					  restRequest    = restRequest
					, restResponse   = restResponse
					, requestContext = mockRequestContext
				);

				var headers = restResponse.getHeaders();

				expect( headers.keyExists( "Access-Control-Allow-Headers" ) ).toBeTrue();
				expect( headers[ "Access-Control-Allow-Headers" ] ).toBe( requestHeaders );
			} );

			it( "should set no 'Access-Control' response headers when CORS requests not allowed", function(){
				var restService        = getService();
				var resource           = { uriPattern="/some/uri/", handler="somehandler", tokens=[], verbs={ GET="testGetMethod", PUT="put", DELETE="delete" } };
				var mockRequestContext = getMockRequestContext();
				var uri                = "/some/test/304958/";
				var api                = "/v1";
				var origin             = "https://foobar.com";
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest( resource=resource, uri=uri, verb="OPTIONS", api=api );

				mockRequestContext.$( "getHttpHeader" ).$args( header="Origin", default="" ).$results( origin );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Method", default="" ).$results( "PUT" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Headers", default="" ).$results( "" );
				restService.$( "isCorsRequestAllowed" ).$args( origin=origin, api=api ).$results( false );

				restService.processOptionsRequest(
					  restRequest    = restRequest
					, restResponse   = restResponse
					, requestContext = mockRequestContext
				);

				var headers = restResponse.getHeaders() ?: {};

				expect( headers.keyExists( "Access-Control-Allow-Origin" ) ).toBeFalse();
				expect( headers.keyExists( "Access-Control-Allow-Methods" ) ).toBeFalse();
				expect( headers.keyExists( "Access-Control-Allow-Headers" ) ).toBeFalse();
			} );

			it( "should set no 'Access-Control' response headers when CORS allowed but method not supported by the resource", function(){
				var restService        = getService();
				var resource           = { uriPattern="/some/uri/", handler="somehandler", tokens=[], verbs={ GET="testGetMethod", PUT="put", POST="post" } };
				var restResponse           = new preside.system.services.rest.PresideRestResponse();
				var mockRequestContext = getMockRequestContext();
				var uri                = "/some/test/304958/";
				var api                = "/v1";
				var origin             = "https://foobar.com";
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest( resource=resource, uri=uri, verb="OPTIONS", api=api );

				mockRequestContext.$( "getHttpHeader" ).$args( header="Origin", default="" ).$results( origin );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Method", default="" ).$results( "DELETE" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Headers", default="" ).$results( "" );
				restService.$( "isCorsRequestAllowed" ).$args( origin=origin, api=api ).$results( true );

				restService.processOptionsRequest(
					  restRequest    = restRequest
					, restResponse   = restResponse
					, requestContext = mockRequestContext
				);

				var headers = restResponse.getHeaders() ?: {};

				expect( headers.keyExists( "Access-Control-Allow-Origin" ) ).toBeFalse();
				expect( headers.keyExists( "Access-Control-Allow-Methods" ) ).toBeFalse();
				expect( headers.keyExists( "Access-Control-Allow-Headers" ) ).toBeFalse();
			} );

			it( "should set a 403 Forbidden status when CORS requests not allowed", function(){
				var restService        = getService();
				var resource           = { uriPattern="/some/uri/", handler="somehandler", tokens=[], verbs={ GET="testGetMethod", PUT="put", DELETE="delete" } };
				var mockRequestContext = getMockRequestContext();
				var uri                = "/some/test/304958/";
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest( resource=resource, uri=uri, verb="OPTIONS" );

				mockRequestContext.$( "getHttpHeader" ).$args( header="Origin", default="" ).$results( "http://mysite.com" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Method", default="" ).$results( "DELETE" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Headers", default="" ).$results( "" );
				restService.$( "isCorsRequestAllowed", false );

				restService.processOptionsRequest(
					  restRequest    = restRequest
					, restResponse   = restResponse
					, requestContext = mockRequestContext
				);

				expect( restResponse.getStatusCode() ).toBe( 403 );
				expect( restResponse.getStatusText() ).toBe( "Forbidden" );
				expect( restResponse.getRenderer() ).toBe( "json" );
				expect( restResponse.getData() ).toBe( {
					  type   = "rest.cors.forbidden"
					, status = 403
					, title  = "Forbidden"
					, detail = "This CORS request is not allowed. Either CORS is disabled for this resource, or the Origin [http://mysite.com] has not been whitelisted."
				} );
			} );

			it( "should set a 403 Forbidden status when CORS requests allowed, but request method is not allowed", function(){
				var restService        = getService();
				var resource           = { uriPattern="/some/uri/", handler="somehandler", tokens=[], verbs={ GET="testGetMethod", PUT="put", DELETE="delete" } };
				var mockRequestContext = getMockRequestContext();
				var uri                = "/some/test/304958/";
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest( resource=resource, uri=uri, verb="OPTIONS" );

				mockRequestContext.$( "getHttpHeader" ).$args( header="Origin", default="" ).$results( "http://mysite.com" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Method", default="" ).$results( "POST" );
				mockRequestContext.$( "getHttpHeader" ).$args( header="Access-Control-Request-Headers", default="" ).$results( "" );
				restService.$( "isCorsRequestAllowed", true );

				restService.processOptionsRequest(
					  restRequest    = restRequest
					, restResponse   = restResponse
					, requestContext = mockRequestContext
				);

				expect( restResponse.getStatusCode() ).toBe( 403 );
				expect( restResponse.getStatusText() ).toBe( "Forbidden" );
				expect( restResponse.getRenderer() ).toBe( "json" );
				expect( restResponse.getData() ).toBe( {
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
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest( uri="/test", verb="GET" );

				restService.processResponse( restRequest, restResponse, mockRequestContext );

				expect( mockRequestContext.$callLog().renderData.len() ).toBe( 1 );
			} );

			it( "should pass the response renderer to the 'type' argument in renderData", function(){
				var restService        = getService();
				var mockRequestContext = getMockRequestContext();
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest( uri="/test", verb="GET" );

				restResponse.setRenderer( "jsonp" );
				restService.processResponse( restRequest, restResponse, mockRequestContext );

				var renderDataArgs = mockRequestContext.$callLog().renderData[1];
				expect( renderDataArgs.keyExists( "type" ) ).toBeTrue();
				expect( renderDataArgs.type ).toBe( "jsonp" );
			} );

			it( "should pass the response mime type to the 'contenttype' argument in renderData", function(){
				var restService        = getService();
				var mockRequestContext = getMockRequestContext();
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest( uri="/test", verb="GET" );

				restResponse.setMimeType( "text/plain" );
				restService.processResponse( restRequest, restResponse, mockRequestContext );

				var renderDataArgs = mockRequestContext.$callLog().renderData[1];
				expect( renderDataArgs.keyExists( "contentType" ) ).toBeTrue();
				expect( renderDataArgs.contentType ).toBe( "text/plain" );
			} );

			it( "should pass the response status code to the 'statusCode' argument in renderData", function(){
				var restService        = getService();
				var mockRequestContext = getMockRequestContext();
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest( uri="/test", verb="GET" );

				restResponse.setStatusCode( 451 );
				restService.processResponse( restRequest, restResponse, mockRequestContext );

				var renderDataArgs = mockRequestContext.$callLog().renderData[1];
				expect( renderDataArgs.keyExists( "statusCode" ) ).toBeTrue();
				expect( renderDataArgs.statusCode ).toBe( 451 );
			} );

			it( "should pass the response status text to the 'statusText' argument in renderData", function(){
				var restService        = getService();
				var mockRequestContext = getMockRequestContext();
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest( uri="/test", verb="GET" );

				restResponse.setStatusText( "This content has been censored and cannot therefor be shown" );
				restService.processResponse( restRequest, restResponse, mockRequestContext );

				var renderDataArgs = mockRequestContext.$callLog().renderData[1];
				expect( renderDataArgs.keyExists( "statusText" ) ).toBeTrue();
				expect( renderDataArgs.statusText ).toBe( "This content has been censored and cannot therefor be shown" );
			} );

			it( "should pass the response data to the 'data' argument in renderData", function(){
				var restService        = getService();
				var mockRequestContext = getMockRequestContext();
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest( uri="/test", verb="GET" );

				restResponse.setData( { test="data" } );
				restService.processResponse( restRequest, restResponse, mockRequestContext );

				var renderDataArgs = mockRequestContext.$callLog().renderData[1];
				expect( renderDataArgs.keyExists( "data" ) ).toBeTrue();
				expect( renderDataArgs.data ).toBe( { test="data" } );
			} );

			it( "should pass an empty string to the renderData 'data' argument, when the data in the response object is NULL", function(){
				var restService        = getService();
				var mockRequestContext = getMockRequestContext();
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest( uri="/test", verb="GET" );

				restResponse.noData();
				restService.processResponse( restRequest, restResponse, mockRequestContext );

				var renderDataArgs = mockRequestContext.$callLog().renderData[1];
				expect( renderDataArgs.keyExists( "data" ) ).toBeTrue();
				expect( renderDataArgs.data ).toBe( "" );
			} );

			it( "should call setHttpHeader() on the request context for each header set in the response", function(){
				var restService        = getService();
				var mockRequestContext = getMockRequestContext();
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest( uri="/test", verb="GET" );

				restResponse.setHeaders({
					  "X-My-Header"      = "my value"
					, "X-Another-Header" = "another value"
					, "X-good-stuff"     = "yes"
				});

				restService.processResponse( restRequest, restResponse, mockRequestContext );

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
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest( uri="/some/uri", verb="HEAD" );

				restResponse.setData( { test="data" } );
				restService.processResponse( restRequest, restResponse, mockRequestContext );

				expect( restResponse.getData() ).toBeNull();
			} );

			it( "should set a 304 response when ETag matches supplied If-None-Match header", function(){
				var restService        = getService();
				var mockRequestContext = getMockRequestContext();
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest( uri="/some/uri", verb="HEAD" );
				var etag               = LCase( Hash( Now() ) );

				restResponse.setData( { test="data" } );
				restResponse.setHeader( "etag", etag );

				restService.$( "setEtag", etag );
				mockRequestContext.$( "getHttpHeader" ).$args( header="If-None-Match", default="" ).$results( etag );
				restService.processResponse( restRequest, restResponse, mockRequestContext );

				expect( restResponse.getData() ).toBeNull();
				expect( restResponse.getRenderer() ).toBe( "plain" );
				expect( restResponse.getStatusCode() ).toBe( 304 );
				expect( restResponse.getStatusText() ).toBe( "Not modified" );
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
				var api         = "/test/some/";

				mockConfigWrapper.$( "getSetting" ).$args(
					  name         = "corsEnabled"
					, api          = api
				).$results( true );

				expect( restService.isCorsRequestAllowed( api=api ) ).toBeTrue();
			} );

			it( "should return false when the result of getSetting call to config wrapper is false", function(){
				var restService = getService();
				var api         = "/test/some/";

				mockConfigWrapper.$( "getSetting" ).$args(
					  name         = "corsEnabled"
					, api          = api
				).$results( false );

				expect( restService.isCorsRequestAllowed( api=api ) ).toBeFalse();
			} );

			it( "should return false when the result of getSetting call to config wrapper is not a boolean value", function(){
				var restService = getService();
				var api         = "/test/some/";

				mockConfigWrapper.$( "getSetting" ).$args(
					  name         = "corsEnabled"
					, api          = api
				).$results( "" );

				expect( restService.isCorsRequestAllowed( api=api ) ).toBeFalse();
			} );
		} );

		describe( "createRestRequest()", function(){
			it( "should return a REST request object prepopulated with information about the request", function(){
				var restService        = getService();
				var api                = "/some";
				var uri                = "/some/test/uri/" & CreateUUId() & "/";
				var resourcePath       = Replace( uri, api, "" );
				var verb               = "OPTIONS";
				var resource           = { test=CreateUUId() };
				var mockRequestContext = getMockRequestContext();

				restService.$( "getVerb", verb );
				restService.$( "getApiForUri" ).$args( restPath=uri ).$results( api );
				restService.$( "getResourceForUri" ).$args( api=api, resourcePath=resourcePath ).$results( resource );

				var restRequest = restService.createRestRequest( uri, mockRequestContext );

				expect( restRequest.getApi() ).toBe( api );
				expect( restRequest.getUri() ).toBe( Replace( uri, api, "" ) );
				expect( restRequest.getResource() ).toBe( resource );
				expect( restRequest.getVerb() ).toBe( verb );
			} );
		} );

		describe( "_validateRestParameters()", function(){
			it( "should validate correctly if there are no required parameters", function(){
				var restService        = getService();
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest(
					resource={
						  handler    = "myResource"
						, tokens     = [ "whatever", "thisisjust", "atest" ]
						, uriPattern = "/test/(.*?)/(.*?)/"
						, verbs      = { post="post", get="get", delete="delete" }
					},
					uri="/some/uri/23",
					verb="get"
				);

				makePublic( restService, "_validateRestParameters" );
				restService._validateRestParameters( restRequest, restResponse, {} );

				expect( restRequest.getFinished() ).toBeFalse();
				expect( restResponse.getStatusCode() ).toBe(200);
			} );
			it( "should detect missing required parameters", function(){
				var restService        = getService();
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest(
					resource={
						  handler    = "api1.subapi.ParamAwareResource"
						, tokens     = [ "param1" ]
						, uriPattern = "^/my/paramaware/pattern/(.*?)$"
						, verbs      = { get="get" }
						, parameterTypes = { get={param1="string", x="numeric", y="date", z="uuid"} }
						, requiredParameters = { get=["param1", "x"] }
					},
					uri="/my/paramaware/pattern/23",
					verb="get"
				);

				restService.$("_translateValidationResultMessages").$results({x="Required field"});
				makePublic( restService, "_validateRestParameters" );

				restService._validateRestParameters( restRequest, restResponse, {param1="xxx"} );

				expect( restRequest.getFinished() ).toBeTrue();
				expect( restResponse.getStatusCode() ).toBe(400);
				expect( restResponse.getStatusText() ).toBe("REST Parameter Validation Error");
				expect( restResponse.getData() ).toBeTypeOf( "struct" );

				var responseData = restResponse.getData();

				expect( responseData ).toHaveKey( "detail" );
				expect( responseData ).toHaveKey( "extra-detail" );
				expect( responseData ).toHaveKey( "status" );
				expect( responseData ).toHaveKey( "title" );
				expect( responseData ).toHaveKey( "type" );
				expect( responseData ).toHaveKey( "x" );

				expect( responseData.detail ).toBe( "A parameter validation error occurred within the REST API" );
				expect( responseData["extra-detail"] ).toBe( "The request has errors in the following parameters: x" );
				expect( responseData.status ).toBe( 400 );
				expect( responseData.title ).toBe( "REST Parameter Validation Error" );
				expect( responseData.x ).toBe( "Required field" );
			} );
			it( "should validate correctly if there are no defined parameter types", function(){
				var restService        = getService();
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest(
					resource={
						  handler    = "myResource"
						, tokens     = [ "whatever", "thisisjust", "atest" ]
						, uriPattern = "/test/(.*?)/(.*?)/"
						, verbs      = { post="post", get="get", delete="delete" }
						, parameterTypes = { get= {} }
						, requiredParameters = { get=[] }
					},
					uri="/some/uri/23",
					verb="get"
				);

				makePublic( restService, "_validateRestParameters" );
				restService._validateRestParameters( restRequest, restResponse, {a=5, b="xxx", c=now()} );
				expect( restRequest.getFinished() ).toBeFalse();
				expect( restResponse.getStatusCode() ).toBe(200);
			} );
			it( "should validate date, numeric and uuid values correctly if supplied parameters are correct", function(){
				var restService        = getService();
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest(
					resource={
						  handler    = "api1.subapi.ParamAwareResource"
						, tokens     = [ "param1" ]
						, uriPattern = "^/my/paramaware/pattern/(.*?)$"
						, verbs      = { get="get" }
						, parameterTypes = { get={param1="string", x="numeric", y="date", z="uuid"} }
						, requiredParameters = { get=["param1", "x"] }
					},
					uri="/my/paramaware/pattern/23",
					verb="get"
				);

				makePublic( restService, "_validateRestParameters" );
				restService._validateRestParameters( restRequest, restResponse, {param1="xxx", x=5, y=now(), z=createUUID()} );
				expect( restRequest.getFinished() ).toBeFalse();
				expect( restResponse.getStatusCode() ).toBe(200);
			} );
			it( "should validate date, numeric and uuid values correctly if supplied parameters are incorrect", function(){
				var restService        = getService();
				var restResponse       = getRestResponse();
				var restRequest        = getRestRequest(
					resource={
						  handler    = "api1.subapi.ParamAwareResource"
						, tokens     = [ "param1" ]
						, uriPattern = "^/my/paramaware/pattern/(.*?)$"
						, verbs      = { get="get" }
						, parameterTypes = { get={param1="string", x="numeric", y="date", z="uuid"} }
						, requiredParameters = { get=["param1", "x"] }
					},
					uri="/my/paramaware/pattern/23",
					verb="get"
				);

				restService.$("_translateValidationResultMessages").$results({x="Parameter 'x' needs to be a numeric value", y="Parameter 'y' needs to be a date value", z="Parameter 'z' needs to be a UUID"});
				makePublic( restService, "_validateRestParameters" );

				makePublic( restService, "_validateRestParameters" );
				restService._validateRestParameters( restRequest, restResponse, {param1="xxx", x="xxx", y="sdfg", z=7} );

				expect( restRequest.getFinished() ).toBeTrue();
				expect( restResponse.getStatusCode() ).toBe(400);
				expect( restResponse.getStatusText() ).toBe("REST Parameter Validation Error");
				expect( restResponse.getData() ).toBeTypeOf( "struct" );

				var responseData = restResponse.getData();

				expect( responseData ).toHaveKey( "detail" );
				expect( responseData ).toHaveKey( "extra-detail" );
				expect( responseData ).toHaveKey( "status" );
				expect( responseData ).toHaveKey( "title" );
				expect( responseData ).toHaveKey( "type" );
				expect( responseData ).toHaveKey( "x" );
				expect( responseData ).toHaveKey( "y" );
				expect( responseData ).toHaveKey( "z" );

				expect( responseData.detail ).toBe( "A parameter validation error occurred within the REST API" );
				expect( responseData["extra-detail"] ).toBe( "The request has errors in the following parameters: x, y, z" );
				expect( responseData.status ).toBe( 400 );
				expect( responseData.title ).toBe( "REST Parameter Validation Error" );
				expect( responseData.x ).toBe( "Parameter 'x' needs to be a numeric value" );
				expect( responseData.y ).toBe( "Parameter 'y' needs to be a date value" );
				expect( responseData.z ).toBe( "Parameter 'z' needs to be a UUID" );
			} );
		} );
	}

	private any function getService( ) {
		variables.mockController       = createStub();
		variables.mockRequestContext   = createStub();
		variables.mockConfigWrapper    = createEmptyMock( "preside.system.services.rest.PresideRestConfigurationWrapper" );
		variables.mockAuthService      = createEmptyMock( "preside.system.services.rest.PresideRestAuthService" );
		variables.mockValidationEngine = createMock( "preside.system.services.validation.ValidationEngine" ).init();
		variables.mockI18n = createMock( "preside.system.services.i18n.i18n" );

		var restService = createMock( "preside.system.services.rest.PresideRestService" );

		restService.$( "_announceInterception" );
		restService.$( "$announceInterception" );
		restService.$( "$raiseError" );
		restService.$( "authenticateRequest" );
		restService.$( "$getRequestContext", mockRequestContext );
		mockRequestContext.$( "cachePage" );
		mockRequestContext.$( "setRestResponse" );
		mockRequestContext.$( "setRestRequest" );

		restService.init(
			  controller           = mockController
			, resourceDirectories  = [ "/resources/rest/dir1", "/resources/rest/dir2" ]
			, configurationWrapper = mockConfigWrapper
			, authService          = mockAuthService
			, validationEngine 	   = mockValidationEngine
			, i18n 				   = mockI18n
		);

		return restService;
	}

	private any function getMockRequestContext() {
		var rc = createEmptyMock( "coldbox.system.web.context.RequestContext" );

		rc.$( "getHttpMethod", "get" );
		rc.$( "setHttpHeader", rc );
		rc.$( "getHttpHeader", "" );
		rc.$( "renderData", rc );
		rc.$( "getCollection", {} );
		rc.$( "getInstanceIdForComparison", CreateUUId() );

		return rc;
	}

	private any function getRestRequest() {
		return new preside.system.services.rest.PresideRestRequest( argumentCollection=arguments );
	}

	private any function getRestResponse() {
		return new preside.system.services.rest.PresideRestResponse( argumentCollection=arguments );
	}

}