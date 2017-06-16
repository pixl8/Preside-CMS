component output=false singleton=true {

// CONSTRUCTOR
	/**
	 * @sessionStorage.inject coldbox:plugin:sessionStorage
	 */
	public any function init( required any sessionStorage, numeric tokenExpiryInSeconds=1200 ) output=false {
		_setSessionStorage( arguments.sessionStorage );
		_setTokenExpiryInSeconds( arguments.tokenExpiryInSeconds );

		return this;
	}

// PUBLIC API
	public string function generateToken() output=false {
		var token      = _getToken();

		if ( StructIsEmpty( token ) or not validateToken( token.value ?: "" ) ) {
			token = { value = Hash( CreateUUId() ), lastActive=Now() };
			_setToken( token );
		}

		return token.value;
	}

	public boolean function validateToken( required string token ) output=false {
		var t = _getToken();

		if ( ( t.value ?: "" ) eq arguments.token ) {
			var expired = DateDiff( "s", t.lastActive, Now() ) gte _getTokenExpiryInSeconds();

			t.lastActive = Now();

			return not expired;
		}
		return false;
	}

// PRIVATE HELPERS
	private struct function _getToken() output=false {
		return _getSessionStorage().getVar( "_csrfToken", {} );
	}

	private void function _setToken( required struct token ) output=false {
		_getSessionStorage().setVar( "_csrfToken", arguments.token );
	}

// GETTERS AND SETTERS
	private any function _getSessionStorage() output=false {
		return _sessionStorage;
	}
	private void function _setSessionStorage( required any sessionStorage ) output=false {
		_sessionStorage = arguments.sessionStorage;
	}

	private numeric function _getTokenExpiryInSeconds() output=false {
		return _tokenExpiryInSeconds;
	}
	private void function _setTokenExpiryInSeconds( required numeric tokenExpiryInSeconds ) output=false {
		_tokenExpiryInSeconds = arguments.tokenExpiryInSeconds;
	}
}