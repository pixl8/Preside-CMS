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
			header name="Content-Security-Policy" value=_injectNonce( _injectAdditionalSources( policy ) );
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

	private function _injectAdditionalSources( required string policy ) {
		var additionalSources = $getRequestContext().getAdditionalCspSources();

		if ( !StructCount( additionalSources ) ) {
			return arguments.policy;
		}

		var directives = _convertPolicyToDirectiveStructure( arguments.policy );

		for( var directive in additionalSources ) {
			if ( !StructKeyExists( directives, directive ) ) {
				directives[ directive ] = [ "'self'" ];
			}

			for( var src in additionalSources[ directive ] ) {
				if ( !ArrayContains( directives[ directive ], src ) ) {
					ArrayAppend( directives[ directive ], src );
				}
			}
		}

		return _convertDirectiveStructureToPolicy( directives );
	}

	private function _convertPolicyToDirectiveStructure( required string policy ) {
		var directives = {};
		for( var directiveAndValues in ListToArray( arguments.policy, ";" ) ) {
			directives[ ListFirst( directiveAndValues, " " ) ] = ListToArray( ListRest( directiveAndValues, " " ), " " );
		}
		return directives;
	}

	private function _convertDirectiveStructureToPolicy( required struct directives ) {
		var policy = [];

		for( var directive in directives ) {
			ArrayAppend( policy, directive & " " & ArrayToList( directives[ directive ], " " ) );
		}

		return ArrayToList( policy, "; " );
	}
}