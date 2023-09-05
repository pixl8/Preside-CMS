/**
 * @singleton      true
 * @presideService true
 */
component {

// CONSTRUCTOR
	/**
	 * @sessionStorage.inject           sessionStorage
	 * @tokenExpiryInSeconds.inject     coldbox:setting:csrf.tokenExpiryInSeconds
	 * @authenticatedSessionOnly.inject coldbox:setting:csrf.authenticatedSessionsOnly
	 */
	public any function init(
		  required any     sessionStorage
		, required numeric tokenExpiryInSeconds
		, required boolean authenticatedSessionOnly
	) {
		_setSessionStorage( arguments.sessionStorage );
		_setTokenExpiryInSeconds( arguments.tokenExpiryInSeconds );
		_setAuthenticatedSessionOnly( arguments.authenticatedSessionOnly );

		return this;
	}

// PUBLIC API
	public string function generateToken( boolean force=false ) {
		if ( skipCsrfValidation() ) {
			return "";
		}

		var generate = arguments.force;
		var token    = "";

		if ( !generate ) {
			token = _getToken();
			generate = StructIsEmpty( token ) || !validateToken( token.value ?: "" );
		}

		if ( generate ) {
			token = { value = Hash( CreateUUId() ), lastActive=Now() };
			_setToken( token );
		}

		return token.value;
	}

	public boolean function validateToken( required string token, boolean regenerate=true ) {
		if ( skipCsrfValidation() ) {
			return true;
		}

		if ( !Len( Trim( arguments.token ) ) ) {
			return false;
		}

		var t = _getToken();

		if ( !Len( Trim( t.value ?: "" ) ) || !IsDate( t.lastActive ?: "" ) ) {
			generateToken( force=true );

			return false;
		}

		if ( t.value == arguments.token ) {
			var expired = DateDiff( "s", t.lastActive, Now() ) >= _getTokenExpiryInSeconds();

			t.lastActive = Now();

			return !expired;
		}

		if ( arguments.regenerate ) {
			generateToken( force=true );
		}

		return false;
	}

	public boolean function skipCsrfValidation() {
		return _getAuthenticatedSessionOnly() && !$isWebsiteUserLoggedIn() && !$isAdminUserLoggedIn() && StructIsEmpty( _getToken() );
	}

// PRIVATE HELPERS
	private struct function _getToken() {
		return _getSessionStorage().getVar( name="_csrfToken", default={} );
	}

	private void function _setToken( required struct token ) {
		_getSessionStorage().setVar( "_csrfToken", arguments.token );
	}

// GETTERS AND SETTERS
	private any function _getSessionStorage() {
		return _sessionStorage;
	}
	private void function _setSessionStorage( required any sessionStorage ) {
		_sessionStorage = arguments.sessionStorage;
	}

	private numeric function _getTokenExpiryInSeconds() {
		return _tokenExpiryInSeconds;
	}
	private void function _setTokenExpiryInSeconds( required numeric tokenExpiryInSeconds ) {
		_tokenExpiryInSeconds = arguments.tokenExpiryInSeconds;
	}

	private boolean function _getAuthenticatedSessionOnly() {
	    return _authenticatedSessionOnly;
	}
	private void function _setAuthenticatedSessionOnly( required boolean authenticatedSessionOnly ) {
	    _authenticatedSessionOnly = arguments.authenticatedSessionOnly;
	}
}
