component output=false hint="Run Railo code through the terminal (there be dragons here, beware!)" {

	property name="jsonRpc2Plugin"           inject="coldbox:myPlugin:JsonRpc2";

	private function index( event, rc, prc ) {
		var params = jsonRpc2Plugin.getRequestParams();
		var promptForInput = { method="runRailo", inputPrompt={ prompt="railo-runner> ", paramName="code" }, params={ activeSession=true } };
		var echo = "";

		if ( ( params.code ?: "" ) == "exit" ) {
			return Chr(10) & "[[b;white;]Goodbye!]" & Chr(10);
		}

		if ( !StructKeyExists( params, "activeSession" ) ) {
			promptForInput.echo = Chr(10) & "[[b;white;]Welcome to the Railo Runner! Enter railo code to execute. Type 'exit' to finish.]" & Chr(10);
		} elseif ( Len( Trim( params.code ?: "" ) ) ) {
			try {
				var result = Evaluate( params.code );

				if ( !IsNull( result ) ) {
					promptForInput.echo = Chr(10) & "[[b;green;]Result:] " & SerializeJson( result ) & Chr(10);
				} else {
					promptForInput.echo = Chr(10) & "[[b;red;]Code executed without result]" & Chr(10);
				}
			} catch ( any e ) {
				promptForInput.echo = Chr(10) & "[[b;red;]Code executed with error:] #e.message#" & Chr(10);
			}
		}

		return promptForInput;
	}
}