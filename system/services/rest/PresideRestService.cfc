/**
 * An object to provide the PresideCMS REST platform's
 * business logic.
 *
 * @autodoc true
 * @singleton
 *
 */
component {

	/**
	 * @resourceDirectories.inject presidecms:directories:handlers/rest-resources
	 * @controller.inject          coldbox
	 *
	 */
	public any function init( required array resourceDirectories, required any controller ) {
		_setApis( new PresideRestResourceReader().readResourceDirectories( arguments.resourceDirectories ) );
		_setController( arguments.controller );

		return this;
	}

	public void function processRequest( required string uri, required any requestContext ) {
		var resource = getResourceForUri( arguments.uri );
		var response = createRestResponse();

		if ( resource.count() ) {
			var args = extractTokensFromUri(
				  uriPattern = resource.uriPattern
				, tokens     = resource.tokens
				, uri        = arguments.uri
			);
			args.response = response;

			_getController().runEvent(
				  event          = "rest-resources.#resource.handler#.#resource.verbs[ arguments.requestContext.getHttpMethod() ]#"
				, prePostExempt  = false
				, private        = true
				, eventArguments = args
			);
		}
	}

	public struct function getResourceForUri( required string restPath ) {
		var apis = _getApis();

		for( var apiPath in _getApiList() ) {
			if ( arguments.restPath.startsWith( apiPath ) ) {
				var apiResources = apis[ apiPath ];
				var resourcePath = arguments.restPath.replace( apiPath, "" );

				for( var resource in apiResources ) {
					if ( ReFindNoCase( resource.uriPattern, resourcePath ) ) {
						return resource;
					}
				}


				break;
			}
		}


		return {};
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