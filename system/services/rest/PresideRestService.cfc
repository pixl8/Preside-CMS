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
	 *
	 */
	public any function init( required array resourceDirectories ) {
		_setResources( new PresideRestResourceReader().readResourceDirectories( arguments.resourceDirectories ) );
		return this;
	}

	public struct function getResourceForRestPath( required string restPath ) {
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

// GETTERS AND SETTERS
	private array function _getResources() {
		return _resources;
	}
	private void function _setResources( required array resources ) {
		_resources = arguments.resources;
	}

}