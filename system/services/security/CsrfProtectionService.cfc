/**
 * @singleton
 *
 */
component {

// CONSTRUCTOR
	/**
	 * @sessionStorage.inject       sessionStorage
	 * @tokenExpiryInSeconds.inject coldbox:setting:csrf.tokenExpiryInSeconds
	 */
	public any function init( required any sessionStorage, required numeric tokenExpiryInSeconds ) {
		_setSessionStorage( arguments.sessionStorage );
		_setTokenExpiryInSeconds( arguments.tokenExpiryInSeconds );

		return this;
	}

// PUBLIC API
	public string function generateToken() {
		var token      = _getToken();

		if ( StructIsEmpty( token ) or not validateToken( token.value ?: "" ) ) {
			token = { value = Hash( CreateUUId() ), lastActive=Now() };
			_setToken( token );
		}

		return token.value;
	}

	public boolean function validateToken( required string token ) {
		var t = _getToken();

		if ( ( t.value ?: "" ) eq arguments.token ) {
			var expired = DateDiff( "s", t.lastActive, Now() ) gte _getTokenExpiryInSeconds();

			t.lastActive = Now();

			return not expired;
		}
		return false;
	}

// PRIVATE HELPERS
	private struct function _getToken() {
		return _getSessionStorage().getVar( "_csrfToken", {} );
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
}
