component {
	property name="configuredToken" inject="coldbox:setting:preside.restauthtoken";

	private string function authenticate() {
		var headers    = getHTTPRequestData( false ).headers;
		var authHeader = headers.Authorization ?: "";
		var token      = "";

		try {
			authHeader = toString( toBinary( listRest( authHeader, ' ' ) ) );
			token      = ListFirst( authHeader, ":" );

			if ( !token.trim().len() ) {
				throw( type="missing.token" );
			}
		} catch( any e ) {
			return "";
		}

		if ( token == configuredToken ) {
			return token;
		}

		return "";
	}
}