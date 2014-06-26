component output=false singleton=true {

// CONSTRUCTOR
	/**
	 * @sessionService.inject SessionService
	 */
	public any function init( required any sessionService, numeric tokenExpiryInSeconds=1200 ) output=false {
		_setSessionService( arguments.sessionService );
		_setTokenExpiryInSeconds( arguments.tokenExpiryInSeconds );

		return this;
	}

// PUBLIC API
	public string function generateToken() output=false {
		var sessionSvc = _getSessionService();
		var token      = _getToken();

		if ( StructIsEmpty( token ) or not validateToken( token.value ?: "" ) ) {
			token = { value = Hash( CreateUUId() ), lastActive=Now() };
			_setToken( token );
		}

		return token.value;
	}

	public boolean function validateToken( required string token ) output=false {
		lock name="csrfProtectionService" timeout="10" {
			var t = _getToken();

			if ( ( t.value ?: "" ) eq arguments.token ) {
				var expired = DateDiff( "s", t.lastActive, Now() ) gte _getTokenExpiryInSeconds();

				t.lastActive = Now();

				return not expired;
			}
		}

		return false;
	}

// PRIVATE HELPERS
	private struct function _getToken() output=false {
		return _getSessionService().getVar( "_csrfToken", {} );
	}

	private void function _setToken( required struct token ) output=false {
		_getSessionService().setVar( "_csrfToken", arguments.token );
	}

// GETTERS AND SETTERS
	private any function _getSessionService() output=false {
		return _sessionService;
	}
	private void function _setSessionService( required any sessionService ) output=false {
		_sessionService = arguments.sessionService;
	}

	private numeric function _getTokenExpiryInSeconds() output=false {
		return _tokenExpiryInSeconds;
	}
	private void function _setTokenExpiryInSeconds( required numeric tokenExpiryInSeconds ) output=false {
		_tokenExpiryInSeconds = arguments.tokenExpiryInSeconds;
	}
}