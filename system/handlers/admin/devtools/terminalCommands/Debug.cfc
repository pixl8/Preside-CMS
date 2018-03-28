component hint="Dev helper to toggle various debugging features" {

	property name="jsonRpc2Plugin" inject="JsonRpc2";
	property name="sessionStorage" inject="sessionStorage";

	private any function index( event, rc, prc ) {
		var params  = jsonRpc2Plugin.getRequestParams();
		var cliArgs = IsArray( params.commandLineArgs ?: "" ) ? params.commandLineArgs : [];

		return "I am a scaffolded command, please finish me off!";
	}

	private function index( event, rc, prc ) {
		var params       = jsonRpc2Plugin.getRequestParams();
		var validOperations = [ "i18n" ];

		params = IsArray( params.commandLineArgs ?: "" ) ? params.commandLineArgs : [];

		if ( !params.len() || !ArrayFindNoCase( validOperations, params[1] ) ) {
			return Chr(10) & "[[b;white;]Usage:] debug [operation]" & Chr(10) & Chr(10)
			               & "Valid operations:" & Chr(10) & Chr(10)
			               & "    [[b;white;]i18n] : Toggles i18n debugging." & Chr(10);
		}

		return runEvent( event="admin.devtools.terminalCommands.debug.#params[1]#", private=true, prePostExempt=true );
	}

	private function i18n( event, rc, prc ) {
		var isDebuggingEnabled = sessionStorage.getVar( "_i18nDebugMode" );
		var newValue           = !( IsTrue( isDebuggingEnabled ?: "" ) );
		var colour             = newValue ? "green" : "red";
		var status             = newValue ? "ON" : "OFF";

		sessionStorage.setVar( "_i18nDebugMode", newValue );

		return  Chr(10) & Chr(10) & "i18n debugging has been turned [[b;#colour#;]#status#]. Please refresh the page."  & Chr(10) & Chr(10);
	}
}