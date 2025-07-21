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
		var policy = $getRequestContext().getContentSecurityPolicy();

		if ( !Len( Trim( policy ) ) ) {
			policy = _getGlobalPolicy();
		}

		if ( Len( Trim( policy ) ) ) {
			policy = _injectNonce( policy );

			header name="Content-Security-Policy" value=policy;
		}
	}

// PRIVATE HELPERS
	private function _getGlobalPolicy() {
		var settings       = $getPresideCategorySettings( "content-security-policy" );
		var settingsPrefix = $getRequestContext().isAdminRequest() ? "admin_" : "";
		var mode           = settings[ settingsPrefix & "csp_mode" ] ?: "";
		var policy         = settings[ settingsPrefix & "manual_policy" ] ?: "";

		switch( mode ) {
			case "manual":
				return ReReplace( Trim( policy ), "[\r\n]+", " ", "all" );
		}

		return "";
	}

	private function _injectNonce( required string policy ) {
		var nonce = $getRequestContext().getRequestNonce();

		return ReplaceNoCase( arguments.policy, "$nonce", nonce, "all" );
	}
}