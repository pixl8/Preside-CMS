/**
 * Handler for authenticating with token authentication
 *
 */
component {

	property name="accessTokenDao" inject="presidecms:object:rest_access_token";

	public string function authenticate() {
		var authHeader = getHTTPRequestData().headers.Authorization ?: "";
		var token      = "";

		try {
			authHeader = toString( toBinary( listRest( authHeader, ' ' ) ) );
			token      = ListFirst( authHeader, ":" );

			if ( !token.trim().len() ) {
				throw( type="missing.token" );
			}
		} catch( any e ) {
			return "Malformed or missing authentication headers."
		}

		var tokenIsValid = accessTokenDao.dataExists(
			  filter       = "token = :token and ( valid_to is null or valid_to >= now() ) and ( valid_from is null or valid_from <= now() )"
			, filterParams = { token=token }
		);

		return tokenIsValid ? "" : "Invalid token";
	}

}