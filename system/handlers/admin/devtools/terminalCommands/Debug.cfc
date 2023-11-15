component hint="Dev helper to toggle various debugging features" extends="preside.system.base.Command" {

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
			var message = newLine();

			message &= writeText( text="Usage: ", type="help", bold=true );
			message &= writeText( text="debug <operation>", type="help", newline=true );
			message &= newLine();

			message &= writeText( text="Valid operations:", type="help", newline=true );
			message &= newLine();

			message &= writeText( text="    i18n", type="help", bold=true );
			message &= writeText( text=" : Toggles i18n debugging", type="help", newline=true );

			return message;
		}

		return runEvent( event="admin.devtools.terminalCommands.debug.#params[1]#", private=true, prePostExempt=true );
	}

	private function i18n( event, rc, prc ) {
		var isDebuggingEnabled = sessionStorage.getVar( "_i18nDebugMode" );
		var newValue           = !( IsTrue( isDebuggingEnabled ?: "" ) );
		var type               = newValue ? "success" : "error";
		var status             = newValue ? "ON" : "OFF";

		sessionStorage.setVar( "_i18nDebugMode", newValue );

		return newLine()
			& writeText( "i18n debugging has been turned " )
			& writeText( text=status, type=type, bold=true )
			& writeText( text=". Please refresh the page.", newline=true );
	}
}