/**
 * The website user manager object provides methods for interacting with the front end users of your sites.
 */
component output=false autodoc=true displayName="Preside Object Service" {

// constructor
	/**
	 * @sessionService.inject sessionService
	 */
	public any function init( required any sessionService ) output=false {
		_setSessionService( arguments.sessionService );
		_setSessionKey( "website_user" );

		return this;
	}

	/**
	 * Returns whether or not the user making the current request is logged in
	 * to the system.
	 */
	public boolean function isLoggedIn() output=false autodoc=true {
		return _getSessionService().exists( name=_getSessionKey() );;
	}


// private accessors
	private any function _getSessionService() output=false {
		return _sessionService;
	}
	private void function _setSessionService( required any sessionService ) output=false {
		_sessionService = arguments.sessionService;
	}

	private string function _getSessionKey() output=false {
		return _sessionKey;
	}
	private void function _setSessionKey( required string sessionKey ) output=false {
		_sessionKey = arguments.sessionKey;
	}
}