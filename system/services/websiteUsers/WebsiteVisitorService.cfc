/**
 * Provides service logic for keeping track of website visitors
 *
 * @autodoc
 * @singleton
 * @presideService
 */
component displayName="Website visitor service" {

// CONSTRUCTOR
	/**
	 * @cookieService.inject cookieService
	 *
	 */
	public any function init( required any cookieService ) {
		_setCookieService( arguments.cookieService );
		_setCookieKey( "vid" );

		return this;
	}

// PUBLIC API
	/**
	 * Returns the ID of the current visitor. If
	 * no ID recorded, and session tracking
	 * enabled for the request, creates a new
	 * visitor record.
	 *
	 * @autodoc
	 */
	public string function getVisitorId() {
		var cookieValue = _getCookieService().getVar( name=_getCookieKey(), default="" );

		if ( Len( Trim( cookieValue ) ) ) {
			return cookieValue;
		}

		return createVisitor();
	}

	/**
	 * Creates a new visitor record and sets
	 * cookie (if sessions are available).
	 * Returns the ID of the visitor.
	 *
	 * @autodoc
	 *
	 */
	public string function createVisitor() {
		if ( _sessionsAreEnabled() ) {
			var visitorId = LCase( CreateUUId() );

			_getCookieService().setVar(
				  name    = _getCookieKey()
				, value   = visitorId
				, expires = _getVIDCookieExpiry()
			);

			return visitorId;
		}

		return "";
	}

// PRIVATE HELPERS
	private boolean function _sessionsAreEnabled() {
		var appSettings = getApplicationSettings( true );

		return IsBoolean( appSettings.sessionManagement ?: "" ) && appSettings.sessionManagement;
	}

	private string function _getVIDCookieExpiry() {
		var VIDCookieExpiry = $getPresideSetting( "tracking", "vid_cookie_expiry" );

		return ( IsNumeric( VIDCookieExpiry ) && VIDCookieExpiry > 0 ? VIDCookieExpiry : "never" );
	}

// GETTERS AND SETTERS
	private any function _getCookieService() {
		return _cookieService;
	}
	private void function _setCookieService( required any cookieService ) {
		_cookieService = arguments.cookieService;
	}

	private string function _getCookieKey() {
		return _cookieKey;
	}
	private void function _setCookieKey( required string cookieKey ) {
		_cookieKey = arguments.cookieKey;
	}
}