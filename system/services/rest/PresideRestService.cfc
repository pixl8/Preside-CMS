/**
 * An object to provide the PresideCMS REST platform's
 * business logic.
 *
 * @autodoc
 * @singleton
 * @presideService
 *
 */
component {

	/**
	 * @resourceDirectories.inject presidecms:directories:handlers/rest-apis
	 * @controller.inject          coldbox
	 *
	 */
	public any function init( required array resourceDirectories, required any controller ) {
		_setApis( new PresideRestResourceReader().readResourceDirectories( arguments.resourceDirectories ) );
		_setController( arguments.controller );

		return this;
	}

	public void function onRestRequest( required string uri, required any requestContext ) {
		var response = createRestResponse();
		var verb     = getVerb( arguments.requestContext );

		_announceInterception( "onRestRequest", { uri=uri, verb=verb, response=response } );

		if ( !response.isFinished() ) {
			processRequest(
				  uri            = arguments.uri
				, verb           = verb
				, requestContext = arguments.requestContext
				, response       = response
			);
		}

		processResponse(
			  response       = response
			, requestContext = arguments.requestContext
			, uri            = arguments.uri
			, verb           = verb
		);
	}

	public void function processRequest( required string uri, required string verb, required any requestContext, required any response ) {
		var resource = getResourceForUri( arguments.uri );

		if ( !resource.count() ) {
			response.setError(
				  errorCode = 404
				, title     = "REST API Resource not found"
				, type      = "rest.resource.not.found"
				, message   = "The requested resource, [#arguments.uri#], did not match any resources in the Preside REST API"
			);

			_announceInterception( "onMissingRestResource", { uri=uri, verb=verb, response=response } );
			return;
		}

		if ( !_verbCanBeHandledByResource( verb, resource ) ) {
			response.setError(
				  errorCode = 405
				, title     = "REST API Method not supported"
				, type      = "rest.method.unsupported"
				, message   = "The requested resource, [#arguments.uri#], does not support the [#UCase( verb )#] method"
			);

			_announceInterception( "onUnsupportedRestMethod", { uri=uri, verb=verb, response=response } );
			return;
		}

		invokeRestResourceHandler(
			  resource       = resource
			, uri            = uri
			, verb           = verb
			, response       = response
			, requestContext = requestContext
		);
	}

	public void function invokeRestResourceHandler(
		  required struct resource
		, required string uri
		, required string verb
		, required any    response
		, required any    requestContext
	) {
		try {
			var coldboxEvent = "rest-apis.#arguments.resource.handler#.";
			var args         = extractTokensFromUri(
				  uriPattern = arguments.resource.uriPattern
				, tokens     = arguments.resource.tokens
				, uri        = arguments.uri
			);

			args.response = arguments.response;

			_announceInterception( "preInvokeRestResource", { uri=arguments.uri, verb=arguments.verb, response=arguments.response, args=args } );
			if ( arguments.response.isFinished() ) {
				return;
			}

			if ( arguments.verb == "HEAD" && !arguments.resource.verbs.keyExists( "HEAD" ) ) {
				coldboxEvent &= arguments.resource.verbs.GET;
			} else {
				coldboxEvent &= arguments.resource.verbs[ arguments.verb ];
			}

			_getController().runEvent(
				  event          = coldboxEvent
				, prePostExempt  = false
				, private        = true
				, eventArguments = args
			);

			_announceInterception( "postInvokeRestResource", { uri=arguments.uri, verb=arguments.verb, response=arguments.response, args=args } );
		} catch( any e ) {
			$raiseError( e );
			arguments.response.setError(
				  argumentCollection = e
				, errorCode          = 500
				, title              = "Unhandled #e.type# exception"
				, type               = "rest.server.error"
			);
			_announceInterception( "onRestError", arguments );
		}
	}

	public void function processResponse( required any response, required any requestContext, required string uri, required string verb ) {
		_dealWithEtags( arguments.response, arguments.requestContext, arguments.verb );

		var headers = response.getHeaders() ?: {};
		for( var headerName in headers ) {
			requestContext.setHttpHeader( name=headerName, value=headers[ headerName ] );
		}

		if ( arguments.verb == "HEAD" ) {
			response.noData();
		}

		requestContext.renderData(
			  type        = response.getRenderer()
			, data        = response.getData() ?: ""
			, contentType = response.getMimeType()
			, statusCode  = response.getStatusCode()
			, statusText  = response.getStatusText()
		);
	}

	public struct function getResourceForUri( required string restPath ) {
		var apiPath      = getApiForUri( arguments.restPath );
		var apis         = _getApis();
		var apiResources = apis[ apiPath ] ?: [];
		var resourcePath = arguments.restPath.replace( apiPath, "" );

		for( var resource in apiResources ) {
			if ( ReFindNoCase( resource.uriPattern, resourcePath ) ) {
				return resource;
			}
		}

		return {};
	}

	public string function getApiForUri( required string restPath ) {
		for( var apiPath in _getApiList() ) {
			if ( arguments.restPath.startsWith( apiPath ) ) {
				return apiPath;
			}
		}

		return "";
	}

	public struct function extractTokensFromUri(
		  required string uriPattern
		, required array  tokens
		, required string uri
	) {
		var findResult = ReFindNoCase( arguments.uriPattern, arguments.uri, 0, true );
		var extracted  = {};

		for( var i=1; i<=arguments.tokens.len(); i++ ) {
			if ( findResult.pos[i+1] ?: 0 ) {
				extracted[ arguments.tokens[ i ] ] = Mid( arguments.uri, findResult.pos[i+1], findResult.len[i+1] );
			}
		}

		return extracted;
	}

	public any function createRestResponse() {
		return new PresideRestResponse();
	}

	public any function getVerb( required any requestContext ) {
		return arguments.requestContext.getHttpHeader(
			  header  = "X-HTTP-Method-Override"
			, default = arguments.requestContext.getHttpMethod()
		);
	}

	public string function getEtag( required any response ) {
		var data = response.getData();

		if ( !IsNull( data ) ) {
			return LCase( Hash( Serialize( response.getData() ) ) );
		}

		return "";
	}

	public string function setEtag( required any response ) {
		var etag = getEtag( arguments.response );

		if ( Len( Trim( etag ) ) ) {
			response.setHeader( "ETag", etag );
		}

		return etag;
	}

// PRIVATE HELPERS
	private array function _getApiList() {
		if ( !variables.keyExists( "_apiList" ) ) {
			_apiList = _getApis().keyArray();
			_apiList.sort( function( a, b ){
				return a.len() > b.len() ? -1 : 1;
			} );
		}

		return _apiList;
	}

	private void function _announceInterception( required string state, struct interceptData={} ) {
		try {
			_getInterceptorService().processState( argumentCollection=arguments );
		} catch( any e ) {
			$raiseError( e );

			if ( IsObject( arguments.interceptData.response ?: "" ) ) {
				arguments.interceptData.response.setError(
					  argumentCollection = e
					, errorCode          = 500
					, title              = "Unhandled #e.type# exception"
					, type               = "rest.server.error"
				);
				_announceInterception( "onRestError", arguments.interceptData );
			}
		}
	}

	private any function _getInterceptorService() {
		return _getController().getInterceptorService();
	}

	private void function _dealWithEtags( required any response, required any requestContext, required string verb ) {
		if ( [ "HEAD", "GET" ].findNoCase( arguments.verb ) ) {
			var etag = setEtag( response );

			if ( Len( Trim( etag ) ) ) {
				var ifNoneMatchHeader = requestContext.getHttpHeader( header="If-None-Match", default="" );
				if ( ifNoneMatchHeader == etag  ) {
					response.noData();
					response.setStatus( 304, "Not modified" );
				}
			}
		}
	}

	private boolean function _verbCanBeHandledByResource( required string verb, required struct resource ) {
		if ( resource.verbs.keyExists( verb ) ) {
			return true;
		}

		if ( verb == "OPTIONS" ) {
			return true;
		}

		if ( verb == "HEAD" && resource.verbs.keyExists( "GET" ) ) {
			return true;
		}

		return false;
	}

// GETTERS AND SETTERS
	private struct function _getApis() {
		return _apis;
	}
	private void function _setApis( required struct apis ) {
		_apis = arguments.apis;
	}


	private any function _getController() {
		return _controller;
	}
	private void function _setController( required any controller ) {
		_controller = arguments.controller;
	}

}