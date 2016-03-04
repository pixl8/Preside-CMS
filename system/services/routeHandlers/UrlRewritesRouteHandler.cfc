/**
 * @singleton
 * @presideservice
 *
 */
component {

// constructor
	/**
	 * @urlRedirectsService.inject delayedInjector:urlRedirectsService
	 */
	public any function init( required any urlRedirectsService ) {
		_setUrlRedirectsService( arguments.urlRedirectsService );

		return this;
	}

// route handler methods
	public boolean function match( required string path, required any event ) {
		if ( event.isAjax() ) {
			return false;
		}

		var path    = event.getCurrentUrl( includeQueryString=true );
		var fullUrl = event.getBaseUrl() & path;

		_getUrlRedirectsService().redirectOnMatch(
			  path    = path
			, fullUrl = fullUrl
		);

		return false;
	}

	public void function translate( required string path, required any event ) {
		return;
	}

	public boolean function reverseMatch( required struct buildArgs, required any event ) {
		return false;
	}

	public string function build( required struct buildArgs, required any event ) {
		return "";
	}

// private getters and setters
	private any function _getUrlRedirectsService() {
		return _urlRedirectsService;
	}
	private void function _setUrlRedirectsService( required any urlRedirectsService ) {
		_urlRedirectsService = arguments.urlRedirectsService;
	}
}