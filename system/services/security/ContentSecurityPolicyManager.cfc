/**
 * Manages the content security policy for the system
 *
 * @singleton      true
 * @presideService true
 */
component {

// CONSTRUCTOR
	function init() {
		return this;
	}

// PUBLIC API
	public void function outputPolicyHeader() {
		var requestPolicy = $getRequestContext().getContentSecurityPolicy();

		if ( Len( Trim( requestPolicy ) ) ) {
			header name="Content-Security-Policy" value=requestPolicy;
			return;
		}

		var globalPolicy = _getGlobalPolicy();

		if ( Len( Trim( globalPolicy ) ) ) {
			header name="Content-Security-Policy" value=globalPolicy;
		}
	}

// PRIVATE HELPERS
	private function _getGlobalPolicy() {
		var settings = $getPresideCategorySettings( "content-security-policy" );

		switch( settings.csp_mode ?: "" ) {
			case "strict":
				return "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:; connect-src 'self' wss:;";
			case "manual":
				return ReReplace( Trim( settings.manual_policy ?: "" ), "[\r\n]+", " ", "all" );
		}

		return "";
	}
}