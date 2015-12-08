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
		_setResources( new PresideRestResourceReader().readResourceDirectories( arguments.resourceDirectories ) );
		_setController( arguments.controller );

		return this;
	}

	public any function processRequest( required string uri, required string verb ) {
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
				  event          = "rest-resources.#resource.handler#.#resource.verbs[ arguments.verb ]#"
				, prePostExempt  = false
				, private        = true
				, eventArguments = args
			);
		}

		return response;
	}

	public struct function getResourceForUri( required string restPath ) {
		for( var resource in _getResources() ) {
			if ( ReFindNoCase( resource.uriPattern, arguments.restPath ) ) {
				return resource;
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

// GETTERS AND SETTERS
	private array function _getResources() {
		return _resources;
	}
	private void function _setResources( required array resources ) {
		_resources = arguments.resources;
	}

	private any function _getController() {
		return _controller;
	}
	private void function _setController( required any controller ) {
		_controller = arguments.controller;
	}

}