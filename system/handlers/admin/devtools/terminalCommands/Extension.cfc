component hint="Manage Preside extensions" extends="preside.system.base.Command" {

	property name="jsonRpc2Plugin"          inject="JsonRpc2";
	property name="extensionManagerService" inject="extensionManagerService";

	private function index( event, rc, prc ) {
		var params             = jsonRpc2Plugin.getRequestParams();
		var subCommands        = [ "list" ];
		var deprecatedCommands = [ "enable", "disable" ]

		params = IsArray( params.commandLineArgs ?: "" ) ? params.commandLineArgs : [];

		if ( !ArrayLen( params ) || !ArrayFindNoCase( subCommands, params[1] ) ) {
			var message = newLine();

			if ( ArrayLen( params ) && ArrayFindNoCase( deprecatedCommands, params[ 1 ] ) ) {
				return message & writeText( text="The '#params[ 1 ]#' sub-command is no longer in use (as of Preside 10.9.0). Extensions are enabled automatically by the system. To disable an extension, simply remove it from your application.", type="error", bold=true, newline=true );
			}

			message &= writeText( text="Usage: ", type="help", bold=true );
			message &= writeText( text="extension <operation>", type="help", newline=2 );

			message &= writeText( text="Valid operations:", type="help", newline=2 );

			message &= writeText( text="    list [<filter>\]", type="help", bold=true );
			message &= writeText( text=" : Lists all installed extensions, or those matching the optional filter string", type="help", newline=true );

			return message;
		}

		try {
			return runEvent(
				  event          = "admin.devtools.terminalCommands.extension.#params[ 1 ]#"
				, private        = true
				, prePostExempt  = true
				, eventArguments = { args={ params=params } }
			);
		} catch ( any e ) {
			return newLine() & writeText( text="Error processing your request: ", type="error", bold=true ) & e.message & newLine();
		}
	}

	private any function list( event, rc, prc ) {
		var extensions    = extensionManagerService.listExtensions();
		var msg           = newLine();
		var tableWidth    = 0;
		var titleWidth    = 5;
		var idWidth       = 2;
		var versionWidth  = 7;
		var priorityWidth = 8;
		var filter        = args.params[ 2 ] ?: "";

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

			msg &= writeText( text=titleBar, type="info", newline=true );
			msg &= writeLine( character="=", length=Len( titleBar ) );

			for( var ext in extensions ){
				if ( Len( filter ) && !FindNoCase( filter, ext.name ) && !FindNoCase( filter, ext.title ) ) {
					continue;
				}
				msg &= writeText( text="  #ext.name#", type="info", bold=true );
				msg &= writeText( text=" #RepeatString( ' ', idWidth-Len( ext.name ) )#"
				     & "  #ext.title# #RepeatString( ' ', titleWidth-Len( ext.title ) )#"
				     & "  #ext.version# #RepeatString( ' ', versionWidth-Len( ext.version ) )#", type="info", newline=true );
			}

			msg &= writeLine( Len( titleBar ) );
		} else {
			msg &= writeText( text="You have no extensions installed", type="info", bold=true, newline=true );
		}

		return msg;
	}
}
