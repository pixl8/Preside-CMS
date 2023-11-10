component hint="Manage Preside extensions" {

	property name="jsonRpc2Plugin"          inject="JsonRpc2";
	property name="extensionManagerService" inject="extensionManagerService";

	private function index( event, rc, prc ) {
		var params             = jsonRpc2Plugin.getRequestParams();
		var subCommands        = [ "list" ];
		var deprecatedCommands = [ "enable", "disable" ]

		params = IsArray( params.commandLineArgs ?: "" ) ? params.commandLineArgs : [];

		if ( !ArrayLen( params ) || !ArrayFindNoCase( subCommands, params[1] ) ) {
			if ( ArrayLen( params ) && ArrayFindNoCase( deprecatedCommands, params[ 1 ] ) ) {
				return Chr(10) & "[[b;red;]The '#params[ 1 ]#' sub-command is no longer in use (as of Preside 10.9.0). Extensions are enabled automatically by the system. To disable an extenion, simply remove it from your application." & Chr(10) & Chr(10)
			}
			return Chr(10) & "[[b;white;]Usage:] extension sub_command" & Chr(10) & Chr(10)
			               & "Valid sub commands:" & Chr(10) & Chr(10)
			               & "    [[b;white;]list [filter\]] : Lists all installed extensions, or those matching the optional filter string" & Chr(10);
		}

		try {
			return runEvent(
				  event          = "admin.devtools.terminalCommands.extension.#params[ 1 ]#"
				, private        = true
				, prePostExempt  = true
				, eventArguments = { args={ params=params } }
			);
		} catch ( any e ) {
			return Chr(10) & "[[b;red;]Error processing your request:] " & e.message & Chr(10);
		}
	}

	private any function list( event, rc, prc ) {
		var extensions    = extensionManagerService.listExtensions();
		var msg           = ""
		var tableWidth    = 0;
		var titleWidth    = 5;
		var idWidth       = 2;
		var versionWidth  = 7;
		var priorityWidth = 8;
		var filter        = args.params[ 2 ] ?: "";
dumplog(extensions);
		for( var ext in extensions ){
			if ( Len( ext.name ) > idWidth ) {
				idWidth = Len( ext.name );
			}
			if ( Len( ext.title ) > titleWidth ) {
				titleWidth = Len( ext.title );
			}
			if ( Len( ext.version ) > versionWidth ) {
				versionWidth = Len( ext.version );
			}
		}

		if ( ArrayLen( extensions ) ) {
			var titleBar = "  ID #RepeatString( ' ', idWidth-2 )#  Title #RepeatString( ' ', titleWidth-5 )#  Version #RepeatString( ' ', versionWidth-7 )#";

			msg = Chr( 10 ) & titleBar & Chr( 10 )
			    & RepeatString( "=", Len( titleBar ) ) & Chr(10);

			for( var ext in extensions ){
				if ( Len( filter ) && !FindNoCase( filter, ext.name ) && !FindNoCase( filter, ext.title ) ) {
					continue;
				}
				msg &= "  [[b;white;]#ext.name#] #RepeatString( ' ', idWidth-Len( ext.name ) )#"
				     & "  #ext.title# #RepeatString( ' ', titleWidth-Len( ext.title ) )#"
				     & "  #ext.version# #RepeatString( ' ', versionWidth-Len( ext.version ) )#" & Chr( 10 );
			}

			msg &= Chr(10) & RepeatString( "-", Len( titleBar ) ) & Chr(10);
		} else {
			msg = Chr(10) & "[[b;white;]You have no extensions installed]" & Chr(10);
		}

		return msg;
	}
}
