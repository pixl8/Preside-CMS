component output=false hint="Manage preside extensions" {

	property name="jsonRpc2Plugin"          inject="coldbox:myPlugin:JsonRpc2";
	property name="extensionManagerService" inject="extensionManagerService";

	private function index( event, rc, prc ) {
		var params      = jsonRpc2Plugin.getRequestParams();
		var subCommands = [ "list", "install", "uninstall", "enable", "disable" ];

		params = IsArray( params.commandLineArgs ?: "" ) ? params.commandLineArgs : [];

		if ( !params.len() || !ArrayFindNoCase( subCommands, params[1] ) ) {
			return Chr(10) & "[[b;white;]Usage:] extension sub_command" & Chr(10) & Chr(10)
			               & "Valid sub commands:" & Chr(10) & Chr(10)
			               & "    [[b;white;]list]      : Lists all installed extensions" & Chr(10)
			               & "    [[b;white;]install]   : Installs an extension" & Chr(10)
			               & "    [[b;white;]uninstall] : Uninstalls an extension" & Chr(10)
			               & "    [[b;white;]enable]    : Enables an extension" & Chr(10)
			               & "    [[b;white;]disable]   : Disables an extension" & Chr(10);
		}

		try {
			return runEvent( event="admin.devtools.terminalCommands.extension.#params[1]#", private=true, prePostExempt=true );
		} catch ( any e ) {
			return Chr(10) & "[[b;red;]Error processing your request:] " & e.message & Chr(10);
		}
	}

	private any function list( event, rc, prc ) output=false {
		var extensions = extensionManagerService.listExtensions();
		var msg           = ""
		var tableWidth    = 0;
		var titleWidth    = 5;
		var idWidth       = 2;
		var versionWidth  = 7;
		var priorityWidth = 8;

		for( var ext in extensions ){
			try {
				StructAppend( ext, extensionManagerService.getExtensionInfo( ext.name ) );
				ext.valid = true;
			} catch ( any e ) {
				ext.valid = false;
			}

			if ( Len( ext.name ) > idWidth ) {
				idWidth = Len( ext.name );
			}
			if ( ext.valid ) {
				if ( Len( ext.title ) > titleWidth ) {
					titleWidth = Len( ext.title );
				}
				if ( Len( ext.version ) > versionWidth ) {
					versionWidth = Len( ext.version );
				}
				if ( Len( ext.priority ) > priorityWidth ) {
					priorityWidth = Len( ext.priority );
				}
			}
		}

		if ( extensions.len() ) {
			var titleBar = "  ID #RepeatString( ' ', idWidth-2 )#  Title #RepeatString( ' ', titleWidth-5 )#  Version #RepeatString( ' ', versionWidth-7 )#  Active   Installed   Valid  Priority";

			msg = Chr( 10 ) & titleBar & Chr( 10 )
			    & RepeatString( "=", Len( titleBar ) ) & Chr(10);

			for( var ext in extensions ){
				msg &= "  [[b;white;]#ext.name#] #RepeatString( ' ', idWidth-Len( ext.name ) )#"
				     & "  #ext.title# #RepeatString( ' ', titleWidth-Len( ext.title ) )#"
				     & "  #ext.version# #RepeatString( ' ', versionWidth-Len( ext.version ) )#"
				     & "  [[b;#ext.active?'green':'red'#;]#YesNoFormat( ext.active )#] #RepeatString( ' ', 6-Len( YesNoFormat( ext.active ) ) )#"
				     & "  [[b;#ext.installed?'green':'red'#;]#YesNoFormat( ext.installed )#] #RepeatString( ' ', 9-Len( YesNoFormat( ext.installed ) ) )#"
				     & "  [[b;#ext.valid?'green':'red'#;]#YesNoFormat( ext.valid )#] #RepeatString( ' ', 5-Len( YesNoFormat( ext.valid ) ) )#"
				     & "  #ext.priority# #RepeatString( ' ', priorityWidth-Len( ext.priority ) )#" & Chr(10);
			}

			msg &= RepeatString( "-", Len( titleBar ) ) & Chr(10);
		} else {
			msg = Chr(10) & "[[b;white;]You have no extensions installed]" & Chr(10);
		}

		return msg;
	}

	private any function install( event, rc, prc ) output=false {
		var params       = jsonRpc2Plugin.getRequestParams();
		var cliArgs      = IsArray( params.commandLineArgs ?: "" ) ? params.commandLineArgs : [];

		if ( ( params.confirmation ?: "" ) == "n" ) {
			return Chr(10) & "[[b;white;]Installation aborted.]" & Chr(10);
		}

		if ( cliArgs.len() lt 2 ) {
			return Chr(10) & "[[b;white;]Usage:] extension install URL_TO_ZIP_FILE" & Chr(10) & Chr(10);
		}

		var extensionUrl = cliArgs[2];

		if ( !ReFindNoCase( "^https?://.*?\.zip$", extensionUrl ) ) {
			return Chr(10) & "[[b;red;]Invalid extension path. Extensions must be a URL to a zip file.] " & Chr(10);
		}

		var tmpDir       = GetTempDirectory() & "/" & Hash( extensionUrl );

		if ( !DirectoryExists( tmpDir ) ) {
			var httpResult = "";
			try {
				http url=extensionUrl getasbinary=true result="httpResult" timeout=60 throwonerror=true;
			} catch ( any e ) {
				return Chr(10) & "[[b;red;]Error fetching extension:] " & e.message & Chr(10);
			}

			var tmpZipFile = GetTempDirectory() & "/" & Hash( extensionUrl ) & ".zip";
			FileWrite( tmpZipFile, httpResult.filecontent );
			try {
				zip action="unzip" file=tmpZipFile destination=GetTempDirectory() & "/" & Hash( extensionUrl );
			} catch ( any e ) {
				FileDelete( tmpZipFile );
				return Chr(10) & "[[b;red;]Error unpacking extension (invalid zip archive?):] " & e.message & Chr(10);
			}
			FileDelete( tmpZipFile );
		}

		if ( ( params.confirmation ?: "" ) != "y" ) {
			try {
				var extensionInfo = extensionManagerService.getExtensionInfo( tmpDir );

				return {
					  method      = "extension"
					, params      = params
					, echo        = Chr(10) & "[[b;white;]Extension, '#extensionInfo.title#', downloaded. Details:]" & Chr(10) & Chr(10)
                                            & "    [[b;white;]ID      :] " & extensionInfo.id & Chr(10)
                                            & "    [[b;white;]Title   :] " & extensionInfo.title & Chr(10)
                                            & "    [[b;white;]Author  :] " & extensionInfo.author & Chr(10)
                                            & "    [[b;white;]Version :] " & extensionInfo.version & Chr(10)
					, inputPrompt = { prompt="Are you sure you want to install this extension? (Y/N): ", required=true, validityRegex="^[YyNn]$", paramName="confirmation" }
				};

			} catch( "ExtensionManager.missingManifest" e ) {
				DirectoryDelete( tmpDir, true );
				return Chr(10) & "[[b;red;]Invalid preside extension. No Manifest file present.] " & Chr(10);
			} catch( "ExtensionManager.invalidManifest" e ) {
				DirectoryDelete( tmpDir, true );
				return Chr(10) & "[[b;red;]Invalid preside extension. Manifest file is not a valid preside manifest.json file.] " & Chr(10);
			} catch ( any e ) {
				DirectoryDelete( tmpDir, true );
				return Chr(10) & "[[b;red;]Error reading extension:] " & e.message & Chr(10);
			}
		}

		try {
			extensionManagerService.installExtension( tmpDir );

		} catch ( any e ) {
			DirectoryDelete( tmpDir, true );
			return Chr(10) & "[[b;red;]Error installing extension:] " & e.message & Chr(10);
		}

		DirectoryDelete( tmpDir, true );

		return Chr(10) & "[[b;green;]Extension installed :)] [[b;yellow;]You will need to do a full application reload for changes to take effect]" & Chr(10);
	}

	private any function uninstall( event, rc, prc ) output=false {
		var params  = jsonRpc2Plugin.getRequestParams();
		var cliArgs = IsArray( params.commandLineArgs ?: "" ) ? params.commandLineArgs : [];

		if ( cliArgs.len() lt 2 ) {
			return Chr(10) & "[[b;white;]Usage:] extension uninstall EXTENSION_NAME" & Chr(10) & Chr(10);
		}

		if ( !StructKeyExists( params, "confirmation" ) ) {
			return {
				  params      = params
				, method      = "extension"
				, echo        = Chr(10)
				, inputPrompt = { prompt="[[b;white;]Are you sure you want to uninstall the extension? (Y/N):] ", paramName="confirmation", required=true, validityRegex="^[YyNn]$" }
			};
		}

		if ( params.confirmation != "y" ) {
			return Chr(10) & "[[b;white;]Aborted.]";
		}

		extensionManagerService.uninstallExtension( cliArgs[2] );

		return Chr(10) & "[[b;green;]Extension uninstalled :)] [[b;yellow;]You will need to do a full application reload for changes to take effect]" & Chr(10);
	}

	private any function enable( event, rc, prc ) output=false {
		var params      = jsonRpc2Plugin.getRequestParams();

		params = IsArray( params.commandLineArgs ?: "" ) ? params.commandLineArgs : [];

		if ( params.len() lt 2 ) {
			return Chr(10) & "[[b;white;]Usage:] extension enable extension_name" & Chr(10) & Chr(10);
		}

		extensionManagerService.activateExtension( params[2] );

		return Chr(10) & "[[b;green;]Extension, #params[2]#, is enabled.] [[b;yellow;]You will need to do a full application reload for changes to take effect]" & Chr(10);
	}

	private any function disable( event, rc, prc ) output=false {
		var params      = jsonRpc2Plugin.getRequestParams();

		params = IsArray( params.commandLineArgs ?: "" ) ? params.commandLineArgs : [];

		if ( params.len() lt 2 ) {
			return Chr(10) & "[[b;white;]Usage:] extension disable extension_name" & Chr(10) & Chr(10);
		}

		extensionManagerService.deActivateExtension( params[2] );

		return Chr(10) & "[[b;green;]Extension, #params[2]#, is disabled.] [[b;yellow;]You will need to do a full application reload for changes to take effect]" & Chr(10);
	}
}