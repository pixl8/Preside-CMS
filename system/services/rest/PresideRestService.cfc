/**
 * An object to provide the Preside REST platform's
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
	 * @authService.inject          presideRestAuthService
	 * @validationEngine.inject     validationEngine
	 */
	public any function init(
		required array resourceDirectories,
		required any   controller,
		required any   configurationWrapper,
		required any   authService,
		required any   validationEngine
	) {
		_readResourceDirectories( arguments.resourceDirectories );
		_setController( arguments.controller );
		_setConfigurationWrapper( arguments.configurationWrapper );
		_setAuthService( arguments.authService );
		_setValidationEngine( arguments.validationEngine );

		_createParameterValidationRuleSets();

		return this;
	}

	public array function listApis() {
		var apis          = Duplicate( _getApiList() );
		var configWrapper = _getConfigurationWrapper();

		for( var i=1; i<=apis.len(); i++ ) {
			var apiId = apis[ i ];
			var api = {
				  id              = apiId
				, description     = configWrapper.getSetting( "description", "", apiId )
				, authProvider    = configWrapper.getSetting( "authProvider", "", apiId )
				, hideFromManager = configWrapper.getSetting( "hideFromManager", "", apiId )
			};

			apis[ i ] = api;
		}

		return apis;
	}

	public void function onRestRequest( required string uri, required any requestContext ) {
		var restResponse = createRestResponse();
		var restRequest  = createRestRequest( arguments.uri, arguments.requestContext );
		var event        = $getRequestContext();

		event.cachePage( false );
		event.setRestResponse( restResponse );
		event.setRestRequest( restRequest );

		_announceInterception( "onRestRequest", { restRequest=restRequest, restResponse=restResponse } );

		if ( !restRequest.getFinished() ) {
			if ( restRequest.getVerb() != "OPTIONS" ) {
				authenticateRequest(
					  restRequest    = restRequest
					, restResponse   = restResponse
					, requestContext = arguments.requestContext
				);
			}

			if ( !restRequest.getFinished() ) {
				processRequest(
					  restRequest    = restRequest
					, restResponse   = restResponse
					, requestContext = arguments.requestContext
				);
			}
		}

		processResponse(
			  restRequest    = restRequest
			, restResponse   = restResponse
			, requestContext = arguments.requestContext
		);
	}

	public void function authenticateRequest( required any restRequest, required any restResponse ) {
		var api          = restRequest.getApi();
		var authProvider = getAuthenticationProvider( api );

		if ( authProvider.len() ) {
			_getAuthService().authenticate(
				  provider     = authProvider
				, restRequest  = restRequest
				, restResponse = restResponse
			);
		}
	}

	public string function getAuthenticationProvider( required string api ) {
		return _getConfigurationWrapper().getSetting( "authProvider", "", api );
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

		if ( restRequest.getVerb() == "OPTIONS" && !StructKeyExists( restRequest.getResource().verbs, "OPTIONS" ) ) {
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
			var args         = requestContext.getCollectionWithoutSystemVars();
			var verb         = restRequest.getVerb();
			var resource     = restRequest.getResource();

			args.append( extractTokensFromUri( restRequest ) );
			args.restResponse = arguments.restResponse;
			args.restRequest  = arguments.restRequest;

			_validateRestParameters( restRequest=restRequest, restResponse=restResponse, args=args );
			if ( arguments.restRequest.getFinished() ) {
				return;
			}

			_announceInterception( "preInvokeRestResource", { restRequest=restRequest, restResponse=restResponse, args=args } );
			if ( arguments.restRequest.getFinished() ) {
				return;
			}

			if ( verb == "HEAD" && !StructKeyExists( resource.verbs, "HEAD" ) ) {
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

	public void function processOptionsRequest(
		  required any restRequest
		, required any restResponse
		, required any requestContext
	) {
		var originHeader         = requestContext.getHttpHeader( header="Origin", defaultValue="" );
		var requestMethodHeader  = requestContext.getHttpHeader( header="Access-Control-Request-Method", defaultValue="" );
		var requestHeadersHeader = requestContext.getHttpHeader( header="Access-Control-Request-Headers", defaultValue="" );

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
			if ( arguments.restPath.reFindNoCase( "^" & apiPath ) ) {
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
			  header       = "X-HTTP-Method-Override"
			, defaultValue = arguments.requestContext.getHttpMethod()
		);
	}

	public string function getEtag( required any restResponse ) {
		var data = restResponse.getData();

		if ( !IsNull( local.data ) ) {
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
	private void function _readResourceDirectories( required array resourceDirectories ) {
		var resourceReader = new PresideRestResourceReader();
		var apis           = resourceReader.readResourceDirectories( arguments.resourceDirectories );

		_announceInterception( "postReadRestResourceDirectories", { apis=apis } );
		_setApis( apis );
	}

	private array function _getApiList() {
		if ( !StructKeyExists( variables, "_apiList" ) ) {
			_apiList = _getApis().keyArray();
			_apiList.sort( function( a, b ){
				return a.len() > b.len() ? -1 : 1;
			} );
		}

		return _apiList;
	}

	private void function _announceInterception( required string state, struct interceptData={} ) {
		try {
			$announceInterception( argumentCollection=arguments );
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

	private void function _dealWithEtags( required any restRequest, required any restResponse, required any requestContext ) {
		if ( [ "HEAD", "GET" ].findNoCase( restRequest.getVerb() ) ) {
			var etag = setEtag( restResponse );

			if ( Len( Trim( etag ) ) ) {
				var ifNoneMatchHeader = requestContext.getHttpHeader( header="If-None-Match", defaultValue="" );
				if ( ifNoneMatchHeader == etag  ) {
					restResponse.noData();
					restResponse.setStatus( 304, "Not modified" );
				}
			}
		}
	}

	private boolean function _verbCanBeHandledByResource( required string verb, required struct resource ) {
		if ( StructKeyExists( resource.verbs, verb ) ) {
			return true;
		}

		if ( verb == "OPTIONS" ) {
			return true;
		}

		if ( verb == "HEAD" && StructKeyExists( resource.verbs, "GET" ) ) {
			return true;
		}

		return false;
	}

	private void function _validateRestParameters(
		  required any    restRequest
		, required any    restResponse
		, required struct args
	) {
		var resource    = arguments.restRequest.getResource();
		var verb        = arguments.restRequest.getVerb();
		var rulesetName = _getValidationRulesetName( resource.handler, verb );

		if ( !_validationEngine.rulesetExists( rulesetName ) ) {
			return;
		}

		var validationResult = _validationEngine.validate( rulesetName, args );

		if ( validationResult.validated() ) {
			return;
		}

		arguments.args.error = {
			  type           = "rest.parameter.validation.error"
			, title          = "REST Parameter Validation Error"
			, errorCode      = 400
			, message        = "A parameter validation error occurred within the REST API"
			, detail         = "The request has errors in the following parameters: #validationResult.listErrorFields().toList( ', ' )#"
			, additionalInfo = _translateValidationResultMessages( validationResult.getMessages() )
		};

		_announceInterception( "onRestRequestParameterValidationError", { restRequest=arguments.restRequest, restResponse=arguments.restResponse, args=arguments.args } );
		if ( arguments.restRequest.getFinished() ) {
			return;
		}

		arguments.restResponse.setError( argumentCollection=arguments.args.error );
		arguments.restRequest.finish();
	}

	private void function _createParameterValidationRuleSets() {
		var validator = "";
		var apis      = _getApis();

		for ( var apiRootPath in apis ) {
			for ( var resource in apis[ apiRootPath ] ) {
				for ( var verb in resource.verbs ) {
					var rules = [];
					if ( StructKeyExists( resource.requiredParameters, verb ) ) {
						for ( var param in resource.requiredParameters[ verb ] ) {
							rules.append( {
								  fieldName = param
								, validator = "required"
							} );
						}
					}
					if ( StructKeyExists( resource.parameterTypes, verb ) ) {
						for ( var param in resource.parameterTypes[ verb ] ) {
							var type      = resource.parameterTypes[verb][param];
							var validator = "";

							switch( type ) {
								case "numeric":
									validator = "number";
									break;
								case "date":
								case "uuid":
									validator = type;
							}

							if ( Len( validator ) ) {
								rules.append( {
									  fieldName = param
									, validator = validator
								} );
							}
						}
					}

					// TODO: create a 'isTypeOf' core validator
					// TODO: support 'non-empty string' validators (it's implicit via "required" but not available for optional params)
					// TODO: support custom validators (e.g. via cfargument annotations)
					if (!rules.isEmpty()) {
						_validationEngine.newRuleset(
							  name  = _getValidationRulesetName( resource.handler, verb )
							, rules = rules
						);
					}
				}
			}
		}
	}

	private struct function _translateValidationResultMessages( required struct messages ) {
		var result = {};

		for ( var param in arguments.messages ) {

			// TODO: support arguments.messages[param].params to be replaced in resources
			// e.g. validation.min.default=Must be at least {1}

			result[ param ] = $translateResource(
				  uri  = arguments.messages[ param ].message
				, data = arguments.messages[ param ].params
			);
		}

		return result;
	}

	private string function _getValidationRulesetName( required string handler, required string verb ) {
		return "restparamruleset.#arguments.handler#.#arguments.verb#";
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

	private any function _getAuthService() {
		return _authService;
	}
	private void function _setAuthService( required any authService ) {
		_authService = arguments.authService;
	}

	private any function _getValidationEngine() {
		return _validationEngine;
	}
	private void function _setValidationEngine( required any validationEngine ) {
		_validationEngine = arguments.validationEngine;
	}
}