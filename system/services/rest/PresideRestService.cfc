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

// GETTERS AND SETTERS
	private array function _getResources() {
		return _resources;
	}
	private void function _setResources( required array resources ) {
		_resources = arguments.resources;
	}

}