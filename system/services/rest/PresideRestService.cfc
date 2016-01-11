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
	 * @resourceDirectories.inject  presidecms:directories:handlers/rest-apis
	 * @controller.inject           coldbox
	 * @configurationWrapper.inject presideRestConfigurationWrapper
	 */
	public any function init( required array resourceDirectories, required any controller, required any configurationWrapper ) {
		_setApis( new PresideRestResourceReader().readResourceDirectories( arguments.resourceDirectories ) );
		_setController( arguments.controller );
		_setConfigurationWrapper( arguments.configurationWrapper );

		return this;
	}

	public void function onRestRequest( required string uri, required any requestContext ) {
		var restResponse = createRestResponse();
		var restRequest  = createRestRequest( arguments.uri, arguments.requestContext );

		_announceInterception( "onRestRequest", { restRequest=restRequest, restResponse=restResponse } );

		if ( !restRequest.getFinished() ) {
			processRequest(
				  restRequest    = restRequest
				, restResponse   = restResponse
				, requestContext = arguments.requestContext
			);
		}

		processResponse(
			  restRequest    = restRequest
			, restResponse   = restResponse
			, requestContext = arguments.requestContext
		);
	}

	public void function processRequest( required any restRequest, required any restResponse, required any requestContext ) {
		if ( !restRequest.getResource().count() ) {
			restResponse.setError(
				  errorCode = 404
				, title     = "REST API Resource not found"
				, type      = "rest.resource.not.found"
				, message   = "The requested resource, [#restRequest.getUri()#], did not match any resources in the Preside REST API"
			);

			_announceInterception( "onMissingRestResource", { restRequest=restRequest, restResponse=restResponse } );
			return;
		}

		if ( !_verbCanBeHandledByResource( restRequest.getVerb(), restRequest.getResource() ) ) {
			restResponse.setError(
				  errorCode = 405
				, title     = "REST API Method not supported"
				, type      = "rest.method.unsupported"
				, message   = "The requested resource, [#restRequest.getUri()#], does not support the [#UCase( restRequest.getVerb() )#] method"
			);

			_announceInterception( "onUnsupportedRestMethod", { restRequest=restRequest, restResponse=restResponse } );
			return;
		}

		if ( restRequest.getVerb() == "OPTIONS" && !restRequest.getResource().verbs.keyExists( "OPTIONS" ) ) {
			processOptionsRequest(
				  restRequest    = restRequest
				, restResponse   = restResponse
				, requestContext = requestContext
			);
		} else {
			invokeRestResourceHandler(
				  restRequest    = restRequest
				, restResponse   = restResponse
				, requestContext = requestContext
			);
		}
	}

	public void function invokeRestResourceHandler(
		  required any restRequest
		, required any restResponse
		, required any requestContext
	) {
		try {
			var coldboxEvent = "rest-apis.#restRequest.getResource().handler#.";
			var args         = Duplicate( requestContext.getCollection() );
			var verb         = restRequest.getVerb();
			var resource     = restRequest.getResource();

			args.append( extractTokensFromUri( restRequest ) );
			args.restResponse = arguments.restResponse;
			args.restRequest  = arguments.restRequest;

			// perform generic required parameter validation
			var validationResult = _validateRequiredRestParameters( restRequest=restRequest, restResponse=restResponse, args=args );
			if ( not validationResult.valid ) {
				args.validationErrors = validationResult.errors;
				_announceInterception( "onMissingRequiredRestRequestParameter", { restRequest=restRequest, restResponse=restResponse, args=args } );
				if ( arguments.restRequest.getFinished() ) {
					// the error was handled by a custom interceptor - just return
					return;
				}
				// error was not handled by a custom interceptor
				// TODO: check if a custom exception should be thrown here
				// or whether processing should continue normally and the CF internal exception is thrown on method call
				//throw(type="MissingRequiredRestRequestParameterException", message="There are missing required parameters", detail=serializeJSON(validationResult.errors));
			}

			// perform generic parameter type validation
			validationResult = _validateRestParameterTypes( restRequest=restRequest, restResponse=restResponse, args=args );
			if ( not validationResult.valid ) {
				args.validationErrors = validationResult.errors;
				_announceInterception( "onInvalidRestRequestParameterType", { restRequest=restRequest, restResponse=restResponse, args=args } );
				if ( arguments.restRequest.getFinished() ) {
					// the error was handled by a custom interceptor - just return
					return;
				}
				// error was not handled by a custom interceptor
				// TODO: check if a custom exception should be thrown here
				// or whether processing should continue normally and the CF internal exception is thrown on method call
				//throw(type="InvalidRestRequestParameterTypeException", message="There are invalid parameter types", detail=serializeJSON(validationResult.errors));
			}

			//validateRestRequestParameters( restRequest=restRequest, restResponse=restResponse, args=args );

			_announceInterception( "preInvokeRestResource", { restRequest=restRequest, restResponse=restResponse, args=args } );
			if ( arguments.restRequest.getFinished() ) {
				return;
			}

			if ( verb == "HEAD" && !resource.verbs.keyExists( "HEAD" ) ) {
				coldboxEvent &= resource.verbs.GET;
			} else {
				coldboxEvent &= resource.verbs[ verb ];
			}

			_getController().runEvent(
				  event          = coldboxEvent
				, prePostExempt  = false
				, private        = true
				, eventArguments = args
			);

			_announceInterception( "postInvokeRestResource", { restRequest=restRequest, restResponse=restResponse, args=args } );
		} catch( any e ) {
			$raiseError( e );
			restResponse.setError(
				  argumentCollection = e
				, errorCode          = 500
				, title              = "Unhandled #e.type# exception"
				, type               = "rest.server.error"
			);

			_announceInterception( "onRestError", {
				  error        = e
				, restRequest  = restRequest
				, restResponse = restResponse
			} );
		}
	}
/*
	public void function validateRestRequestParameters(
		  required any restRequest
		, required any restResponse
		, required struct args
	) {

		var validationResult = _validateRequiredRestParameters(argumentCollection=arguments);
		if ( not validationResult.valid ) {
			args.validationErrors = validationResult.errors;
			_announceInterception( "onMissingRequiredRestRequestParameter", { restRequest=restRequest, restResponse=restResponse, args=args } );
			if ( arguments.restRequest.getFinished() ) {
				return;
			}
		}

		validationResult = _validateRestParameterTypes(argumentCollection=arguments);
		if ( not validationResult.valid ) {
			args.validationErrors = validationResult.errors;
			_announceInterception( "onInvalidRestRequestParameterType", { restRequest=restRequest, restResponse=restResponse, args=args } );
		}
	}*/

	public void function processOptionsRequest(
		  required any restRequest
		, required any restResponse
		, required any requestContext
	) {
		var originHeader         = requestContext.getHttpHeader( header="Origin", default="" );
		var requestMethodHeader  = requestContext.getHttpHeader( header="Access-Control-Request-Method", default="" );
		var requestHeadersHeader = requestContext.getHttpHeader( header="Access-Control-Request-Headers", default="" );

		if ( !Len( Trim( originHeader ) ) || !Len( Trim( requestMethodHeader ) ) ) {
			restResponse.setError(
				  type      = "rest.options.missing." & ( Len( Trim( originHeader ) ) ? "request.method" : "origin" )
				, title     = "Bad Request"
				, errorCode = 400
				, message   = "Insufficient information. " & ( Len( Trim( originHeader ) ) ? "Access-Control-Request-Method" : "Origin" ) & " request header needed."
			);
			return;
		}

		var isOriginAllowed     = isCorsRequestAllowed( origin=originHeader, api=restRequest.getApi() );
		var isHttpMethodAllowed = _verbCanBeHandledByResource( requestMethodHeader, restRequest.getResource() );

		if ( isOriginAllowed && isHttpMethodAllowed ) {
			restResponse.noData().setStatus( 200, "OK" );
			restResponse.setHeader( "Access-Control-Allow-Origin" , originHeader );
			restResponse.setHeader( "Access-Control-Allow-Methods", requestMethodHeader );
			restResponse.setHeader( "Access-Control-Allow-Headers", requestHeadersHeader );
		} else {
			var message = "";

			if ( isOriginAllowed ) {
				message = "This CORS request is not allowed. The resource at [#restRequest.getUri()#] does not support the [#requestMethodHeader#] method."
			} else {
				message = "This CORS request is not allowed. Either CORS is disabled for this resource, or the Origin [#originHeader#] has not been whitelisted."
			}

			restResponse.setError(
				  type      = "rest.cors.forbidden"
				, title     = "Forbidden"
				, errorCode = 403
				, message   = message
			);
		}
	}

	public boolean function isCorsRequestAllowed( required string api ) {
		var isCorsEnabled = _getConfigurationWrapper().getSetting( name="corsEnabled", api=api );

		return IsBoolean( isCorsEnabled ) && isCorsEnabled;
	}

	public void function processResponse( required any restRequest, required any restResponse, required any requestContext ) {
		_dealWithEtags( arguments.restRequest, arguments.restResponse, arguments.requestContext );

		var headers = restResponse.getHeaders() ?: {};
		for( var headerName in headers ) {
			requestContext.setHttpHeader( name=headerName, value=headers[ headerName ] );
		}

		if ( restRequest.getVerb() == "HEAD" ) {
			restResponse.noData();
		}

		requestContext.renderData(
			  type        = restResponse.getRenderer()
			, data        = restResponse.getData() ?: ""
			, contentType = restResponse.getMimeType()
			, statusCode  = restResponse.getStatusCode()
			, statusText  = restResponse.getStatusText()
		);
	}

	public struct function getResourceForUri( required string api, required string resourcePath ) {
		var apis         = _getApis();
		var apiResources = apis[ api ] ?: [];

		for( var resource in apiResources ) {
			if ( ReFindNoCase( resource.uriPattern, arguments.resourcePath ) ) {
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

	public struct function extractTokensFromUri( required any restRequest ) {
		var resource   = restRequest.getResource();
		var findResult = ReFindNoCase( resource.uriPattern, restRequest.getUri(), 0, true );
		var extracted  = {};

		for( var i=1; i<=resource.tokens.len(); i++ ) {
			if ( findResult.pos[i+1] ?: 0 ) {
				extracted[ resource.tokens[ i ] ] = Mid( restRequest.getUri(), findResult.pos[i+1], findResult.len[i+1] );
			}
		}

		return extracted;
	}

	public any function createRestResponse() {
		return new PresideRestResponse();
	}

	public any function createRestRequest( required string uri, required any requestContext ) {
		var api          = getApiForUri( restPath=arguments.uri );
		var resourcePath = api == "/" ? arguments.uri : ReplaceNoCase( arguments.uri, api, "" );
		var resource     = getResourceForUri( api=api, resourcePath=resourcePath );
		var verb         = getVerb( arguments.requestContext );

		return new PresideRestRequest(
			  api      = api
			, verb     = verb
			, uri      = resourcePath
			, resource = resource
		);
	}

	public any function getVerb( required any requestContext ) {
		return arguments.requestContext.getHttpHeader(
			  header  = "X-HTTP-Method-Override"
			, default = arguments.requestContext.getHttpMethod()
		);
	}

	public string function getEtag( required any restResponse ) {
		var data = restResponse.getData();

		if ( !IsNull( data ) ) {
			return LCase( Hash( Serialize( restResponse.getData() ) ) );
		}

		return "";
	}

	public string function setEtag( required any restResponse ) {
		var etag = getEtag( arguments.restResponse );

		if ( Len( Trim( etag ) ) ) {
			restResponse.setHeader( "ETag", etag );
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

			if ( IsObject( arguments.interceptData.restResponse ?: "" ) ) {
				arguments.interceptData.restResponse.setError(
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

	private void function _dealWithEtags( required any restRequest, required any restResponse, required any requestContext ) {
		if ( [ "HEAD", "GET" ].findNoCase( restRequest.getVerb() ) ) {
			var etag = setEtag( restResponse );

			if ( Len( Trim( etag ) ) ) {
				var ifNoneMatchHeader = requestContext.getHttpHeader( header="If-None-Match", default="" );
				if ( ifNoneMatchHeader == etag  ) {
					restResponse.noData();
					restResponse.setStatus( 304, "Not modified" );
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

	private struct function _validateRequiredRestParameters(
		required any restRequest
		, required any restResponse
		, required struct args
	) {
		var restResource = arguments.restRequest.getResource();
        var restVerb = arguments.restRequest.getVerb();
        var requiredParameters = restResource.requiredParameters[restVerb] ?: [];
        var validationResult = {valid=true, errors=[]};

        if (requiredParameters.isEmpty()) {
        	return validationResult;
        }

        for ( var requiredParameterName in requiredParameters ) {
            if ( !arguments.args.keyExists( requiredParameterName ) ) {
            	validationResult.valid = false;
            	validationResult.errors.append("Missing required parameter '#requiredParameterName#'");
            }
        }
        return validationResult;
	}

	private struct function _validateRestParameterTypes(
		required any restRequest
		, required any restResponse
		, required struct args
	) {
		var restResource = arguments.restRequest.getResource();
        var restVerb = arguments.restRequest.getVerb();
        var restArgs = arguments.args;
        var parameterTypes = restResource.parameterTypes[restVerb] ?: {};
        var validationResult = {valid=true, errors=[]};

        if (parameterTypes.isEmpty()) {
        	return validationResult;
        }

        var paramValue = "";
        var paramValue = "";
        var errorMessage = "";

        for (var paramName in restArgs) {
            if (!parameterTypes.keyExists(paramName)) {
                continue;
            }
            paramValue = restArgs[paramName];
            paramType = parameterTypes[paramName];
            errorMessage = "";
            if (paramType eq "numeric" and not isNumeric(paramValue)) {
                errorMessage = "Parameter '#paramName#' needs to be a numeric value";
            }
            else if (paramType eq "date" and not isDate(paramValue)) {
                errorMessage = "Parameter '#paramName#' needs to be a date value";
            }
            else if (paramType eq "uuid" and not isValid("uuid", paramValue)) {
                errorMessage = "Parameter '#paramName#' needs to be a UUID";
            }
            if ( len(errorMessage) ) {
            	validationResult.valid = false;
            	validationResult.errors.append(errorMessage);
            }
            // TODO: add more generic type validations
        }

        return validationResult;
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

	private any function _getConfigurationWrapper() {
		return _configurationWrapper;
	}
	private void function _setConfigurationWrapper( required any configurationWrapper ) {
		_configurationWrapper = arguments.configurationWrapper;
	}

}