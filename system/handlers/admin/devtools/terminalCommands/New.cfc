component output=false hint="Create various preside system entities such as widgets and page types" {

	property name="jsonRpc2Plugin"     inject="coldbox:myPlugin:JsonRpc2";
	property name="scaffoldingService" inject="scaffoldingService";

	private function index( event, rc, prc ) {
		var params = jsonRpc2Plugin.getRequestParams();
		var validTargets = [ "widget", "terminalcommand", "pagetype", "object" ];

		params = IsArray( params.commandLineArgs ?: "" ) ? params.commandLineArgs : [];

		if ( !params.len() || !ArrayFindNoCase( validTargets, params[1] ) ) {
			return Chr(10) & "[[b;white;]Usage:] new target_type" & Chr(10) & Chr(10)
			               & "Valid target types:" & Chr(10) & Chr(10)
			               & "    [[b;white;]widget]          : Creates files for a new preside widget." & Chr(10)
			               & "    [[b;white;]pagetype]        : Creates files for a new page type." & Chr(10)
			               & "    [[b;white;]object]          : Creates a new preside object." & Chr(10)
			               & "    [[b;white;]terminalcommand] : Creates a new terminal command!" & Chr(10);
		}

		return runEvent( event="admin.devtools.terminalCommands.new.#params[1]#", private=true, prePostExempt=true );
	}

	private function widget( event, rc, prc ) output=false {
		var params               = jsonRpc2Plugin.getRequestParams();
		var userInputPrompts     = [];

		if ( !StructKeyExists( params, "id" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Widget ID: ", required=true, paramName="id"} );
		}
		if ( !StructKeyExists( params, "name" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Widget name: ", required=true, paramName="name"} );
		}
		if ( !StructKeyExists( params, "description" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Description: ", required=false, paramName="description"} );
		}
		if ( !StructKeyExists( params, "icon" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Icon class, we use font-awesome 4: ", required=false, default="fa-magic", paramName="icon"} );
		}
		if ( !StructKeyExists( params, "createHandler" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Create handler?", required=true, default="N", paramName="createHandler", validityRegex="^[YyNn]$" } );
		}
		if ( !StructKeyExists( params, "options" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Config options, e.g. 'title,max_items,feed_url': ", required=false, paramName="options"} );
		}
		if ( !StructKeyExists( params, "extension" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Extension name, leave blank for no extension: ", required=false, paramName="extension"} );
		}

		if ( ArrayLen( userInputPrompts ) ) {
			return {
				  echo        = Chr(10) & "[[b;white;]:: Welcome to the new widget wizard]" & Chr(10) & Chr(10)
				, inputPrompt = userInputPrompts
				, method      = "new"
				, params      = params
			};
		}

		var filesCreated = [];
		try {
			filesCreated = scaffoldingService.scaffoldWidget(
				  id            = params.id
				, name          = params.name
				, description   = params.description
				, icon          = params.icon
				, options       = params.options
				, extension     = params.extension
				, createHandler = ( params.createHandler == "y" ? true : false )
			);
		} catch ( any e ) {
			return Chr(10) & "[[b;red;]Error creating #params.id# widget:] [[b;white;]#e.message#]" & Chr(10);
		}

		var msg = Chr(10) & "[[b;white;]Your widget, '#params.id#', has been scaffolded.] The following files were created:" & Chr(10) & Chr(10);
		for( var file in filesCreated ) {
			msg &= "    " & file & Chr(10);
		}

		return msg;
	}

	private function pagetype( event, rc, prc ) output=false {
		var params               = jsonRpc2Plugin.getRequestParams();
		var userInputPrompts     = [];

		if ( !StructKeyExists( params, "id" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Page type ID: ", required=true, paramName="id"} );
		}
		if ( !StructKeyExists( params, "name" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Friendly name: ", required=true, paramName="name"} );
		}
		if ( !StructKeyExists( params, "description" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Description: ", required=false, paramName="description"} );
		}
		if ( !StructKeyExists( params, "icon" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Icon class, we use font-awesome 4: ", required=false, default="fa-file-o", paramName="icon"} );
		}
		if ( !StructKeyExists( params, "createHandler" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Create hanlder?", required=true, default="N", paramName="createHandler", validityRegex="^[YyNn]$" } );
		}
		if ( !StructKeyExists( params, "fields" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Config fields, e.g. 'title,max_items,feed_url': ", required=false, paramName="fields"} );
		}
		if ( !StructKeyExists( params, "extension" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Extension name, leave blank for no extension: ", required=false, paramName="extension"} );
		}

		if ( ArrayLen( userInputPrompts ) ) {
			return {
				  echo        = Chr(10) & "[[b;white;]:: Welcome to the new page type wizard]" & Chr(10) & Chr(10)
				, inputPrompt = userInputPrompts
				, method      = "new"
				, params      = params
			};
		}

		var filesCreated = [];
		try {
			filesCreated = scaffoldingService.scaffoldPageType(
				  id            = params.id
				, name          = params.name
				, description   = params.description
				, icon          = params.icon
				, fields        = params.fields
				, extension     = params.extension
				, createHandler = ( params.createHandler == "y" ? true : false )
			);
		} catch ( any e ) {
			return Chr(10) & "[[b;red;]Error creating #params.id# page type:] [[b;white;]#e.message#]" & Chr(10);
		}

		var msg = Chr(10) & "[[b;white;]Your page type, '#params.id#', has been scaffolded.] The following files were created:" & Chr(10) & Chr(10);
		for( var file in filesCreated ) {
			msg &= "    " & file & Chr(10);
		}

		return msg;
	}

	private function object( event, rc, prc ) output=false {
		var params               = jsonRpc2Plugin.getRequestParams();
		var userInputPrompts     = [];

		if ( !StructKeyExists( params, "id" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Object ID: ", required=true, paramName="id"} );
		}
		if ( !StructKeyExists( params, "name" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Friendly name: ", required=true, paramName="name"} );
		}
		if ( !StructKeyExists( params, "pluralName" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Friendly name (plural): ", required=true, paramName="pluralName"} );
		}
		if ( !StructKeyExists( params, "description" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Description: ", required=false, paramName="description"} );
		}
		if ( !StructKeyExists( params, "dmGroup" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Datamanager group, leave blank for no group: ", required=false, paramName="dmGroup"} );
		}
		if ( !StructKeyExists( params, "properties" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Properties, e.g. 'title,max_items,feed_url': ", required=false, paramName="properties"} );
		}
		if ( !StructKeyExists( params, "extension" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Extension name, leave blank for no extension: ", required=false, paramName="extension"} );
		}

		if ( ArrayLen( userInputPrompts ) ) {
			return {
				  echo        = Chr(10) & "[[b;white;]:: Welcome to the new preside object wizard]" & Chr(10) & Chr(10)
				, inputPrompt = userInputPrompts
				, method      = "new"
				, params      = params
			};
		}

		var filesCreated = [];
		try {
			filesCreated = scaffoldingService.scaffoldPresideObject(
				  objectName       = params.id
				, name             = params.name
				, pluralName       = params.pluralName
				, description      = params.description
				, properties       = params.properties
				, dataManagerGroup = params.dmGroup
				, extension        = params.extension
			);
		} catch ( any e ) {
			return Chr(10) & "[[b;red;]Error creating #params.id# object:] [[b;white;]#e.message#]" & Chr(10);
		}

		var msg = Chr(10) & "[[b;white;]Your preside object, '#params.id#', has been scaffolded.] The following files were created:" & Chr(10) & Chr(10);
		for( var file in filesCreated ) {
			msg &= "    " & file & Chr(10);
		}

		return msg;
	}

	private function terminalCommand( event, rc, prc ) output=false {
		var params           = jsonRpc2Plugin.getRequestParams();
		var userInputPrompts = [];

		if ( !StructKeyExists( params, "name" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Command name: ", required=true, paramName="name" } );
		}
		if ( !StructKeyExists( params, "helpText" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Help text: ", required=false, paramName="helpText" } );
		}
		if ( !StructKeyExists( params, "extension" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Extension name, leave blank for no extension: ", required=false, paramName="extension"} );
		}

		if ( ArrayLen( userInputPrompts ) ) {
			return {
				  echo        = Chr(10) & "[[b;white;]:: Welcome to the new terminal command wizard]" & Chr(10) & Chr(10)
				, inputPrompt = userInputPrompts
				, method      = "new"
				, params      = params
			};
		}

		try {
			filesCreated = scaffoldingService.scaffoldTerminalCommand(
				  name      = params.name
				, helpText  = params.helpText
				, extension = params.extension
			);
		} catch ( any e ) {
			return Chr(10) & "[[b;red;]Error creating command:] [[b;white;]#e.message#]" & Chr(10);
		}

		var msg = Chr(10) & "[[b;white;]Your command has been created!] The following files were created:" & Chr(10) & Chr(10);
			msg &= "    " & filesCreated & Chr(10);

		return msg;
	}
}