component hint="SSL certificates" {

	property name="jsonRpc2Plugin"          inject="JsonRpc2";

	private function index( event, rc, prc ) {
		var params             = jsonRpc2Plugin.getRequestParams();
		var subCommands        = [ "import", "list" ];

		params = IsArray( params.commandLineArgs ?: "" ) ? params.commandLineArgs : [];

		if ( !params.len() || !ArrayFindNoCase( subCommands, params[ 1 ] ) ) {
			return Chr(10) & "[[b;white;]Usage:] sslcert sub_command" & Chr(10) & Chr(10)
			               & "Valid sub commands:" & Chr(10) & Chr(10)
			               & "    [[b;white;]list] : Lists a host's ssl certificates" & Chr(10)
			               & "    [[b;white;]import] : Imports a host's ssl certificate" & Chr(10);
		}

		try {
			return runEvent( event="admin.devtools.terminalCommands.sslcert.#params[1]#", private=true, prePostExempt=true );
		} catch ( any e ) {
			return Chr(10) & "[[b;red;]Error processing your request:] " & e.message & Chr(10);
		}
	}

	private function import( event, rc, prc ) {
		var params               = jsonRpc2Plugin.getRequestParams();
		var userInputPrompts     = [];

		if ( !StructKeyExists( params, "host" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Host: ", required=true, paramName="host"} );
		}
		if ( !StructKeyExists( params, "port" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Port: ", required=false, paramName="port", default="443", validityRegex="^\d+$"} );
		}

		if ( ArrayLen( userInputPrompts ) ) {
			return {
				  echo        = Chr(10) & "[[b;white;]:: SSL Certificate Tool]" & Chr(10) & Chr(10)
				, inputPrompt = userInputPrompts
				, method      = "sslcert"
				, params      = params
			};
		}

		try {
			sslCertificateInstall( params.host, params.port?:443 );
		} catch ( any e ) {
			return Chr(10) & "[[b;red;]Error importing certificate for #params.host#:#(params.port?:443)#:] [[b;white;]#e.message#]" & Chr(10);
		}

		var msg = Chr(10) & "[[b;white;]The SSL certificate for #params.host#:#(params.port?:443)# has been imported.]";

		return msg;
	}

	private any function list( event, rc, prc ) {
		var params               = jsonRpc2Plugin.getRequestParams();
		var userInputPrompts     = [];

		if ( !StructKeyExists( params, "host" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Host: ", required=true, paramName="host"} );
		}
		if ( !StructKeyExists( params, "port" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Port: ", required=false, paramName="port", default="443", validityRegex="^\d+$"} );
		}

		if ( ArrayLen( userInputPrompts ) ) {
			return {
				  echo        = Chr(10) & "[[b;white;]:: SSL Certificate Tool]" & Chr(10) & Chr(10)
				, inputPrompt = userInputPrompts
				, method      = "sslcert"
				, params      = params
			};
		}

		var result = new Query();

		try {
			var result = sslCertificateList( params.host, params.port?:443 );
		} catch ( any e ) {
			return Chr(10) & "[[b;red;]Error fetching certificates for #params.host#:#(params.port?:443)#:] [[b;white;]#e.message#]" & Chr(10);
		}

		var msg = Chr(10) & "[[b;white;]The SSL certificate for #params.host#:#(params.port?:443)#: #serializeJSON(result)#]";

		return msg;
	}
}