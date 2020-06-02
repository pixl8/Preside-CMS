component hint="Create various preside system entities such as widgets and page types" {

	property name="jsonRpc2Plugin"     inject="JsonRpc2";
	property name="scaffoldingService" inject="scaffoldingService";

	private function index( event, rc, prc ) {
		var params = jsonRpc2Plugin.getRequestParams();
		var validTargets = [ "widget", "terminalcommand", "pagetype", "object", "extension", "configform", "formcontrol", "emailtemplate", "ruleexpression", "notification" ];

		params = IsArray( params.commandLineArgs ?: "" ) ? params.commandLineArgs : [];

		if ( !params.len() || !ArrayFindNoCase( validTargets, params[1] ) ) {
			return Chr(10) & "[[b;white;]Usage:] new target_type" & Chr(10) & Chr(10)
			               & "Valid target types:" & Chr(10) & Chr(10)
			               & "    [[b;white;]widget]          : Creates files for a new preside widget." & Chr(10)
			               & "    [[b;white;]pagetype]        : Creates files for a new page type." & Chr(10)
			               & "    [[b;white;]object]          : Creates a new preside object." & Chr(10)
			               & "    [[b;white;]extension]       : Creates a new preside extension." & Chr(10)
			               & "    [[b;white;]configform]      : Creates a new system config form." & Chr(10)
			               & "    [[b;white;]formcontrol]     : Creates a new form control." & Chr(10)
			               & "    [[b;white;]emailtemplate]   : Creates a new email template." & Chr(10)
			               & "    [[b;white;]ruleexpression]  : Creates a new rules engine expression" & Chr(10)
			               & "    [[b;white;]notification]    : Creates a new notification" & Chr(10)
			               & "    [[b;white;]terminalcommand] : Creates a new terminal command!" & Chr(10);
		}

		return runEvent( event="admin.devtools.terminalCommands.new.#params[1]#", private=true, prePostExempt=true );
	}

	private function widget( event, rc, prc ) {
		var params               = jsonRpc2Plugin.getRequestParams();
		var userInputPrompts     = [];

		if ( !StructKeyExists( params, "id" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Widget ID: ", required=true, paramName="id"} );
		}
		if ( !StructKeyExists( params, "name" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Widget name: ", required=true, paramName="name"} );
		}
		if ( !StructKeyExists( params, "categories" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Categories (e.g. newlsetter - leave blank for no category): ", required=false, paramName="categories" } );
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
				, categories    = params.categories
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

	private function notification( event, rc, prc ) {
		var params               = jsonRpc2Plugin.getRequestParams();
		var userInputPrompts     = [];

		if ( !StructKeyExists( params, "notificationId" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Notification ID: ", required=true, paramName="notificationId"} );
		}
		if ( !StructKeyExists( params, "title" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Title: ", required=true, paramName="title"} );
		}
		if ( !StructKeyExists( params, "description" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Description: ", required=false, paramName="description"} );
		}
		if ( !StructKeyExists( params, "icon" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Icon class, we use font-awesome 4: ", required=false, default="fa-magic", paramName="icon"} );
		}
		if ( !StructKeyExists( params, "dataTableTitle" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Data table title: ", required=false, paramName="dataTableTitle"} );
		}
		if ( !StructKeyExists( params, "extension" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Extension name, leave blank for no extension: ", required=false, paramName="extension"} );
		}

		if ( ArrayLen( userInputPrompts ) ) {
			return {
				  echo        = Chr(10) & "[[b;white;]:: Welcome to the new notification wizard]" & Chr(10) & Chr(10)
				, inputPrompt = userInputPrompts
				, method      = "new"
				, params      = params
			};
		}

		var filesCreated = [];
		try {
			filesCreated = scaffoldingService.scaffoldNotification(
				  notificationId = params.notificationId
				, title          = params.title
				, description    = params.description
				, icon           = params.icon
				, dataTableTitle = params.dataTableTitle
				, extension      = params.extension
			);
		} catch ( any e ) {
			return Chr(10) & "[[b;red;]Error creating #params.notificationId# notification:] [[b;white;]#e.message#]" & Chr(10);
		}

		var msg = Chr(10) & "[[b;white;]Your notification, '#params.notificationId#', has been scaffolded.] The following files were created:" & Chr(10) & Chr(10);
		for( var file in filesCreated ) {
			msg &= "    " & file & Chr(10);
		}

		return msg;
	}

	private function pagetype( event, rc, prc ) {
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
			ArrayAppend( userInputPrompts, { prompt="Create handler?", required=true, default="N", paramName="createHandler", validityRegex="^[YyNn]$" } );
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

	private function object( event, rc, prc ) {
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

	private function extension( event, rc, prc ) {
		var params           = jsonRpc2Plugin.getRequestParams();
		var userInputPrompts = [];

		if ( !StructKeyExists( params, "id" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Extension ID: ", required=true, paramName="id" } );
		}
		if ( !StructKeyExists( params, "title" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Title: ", required=false, paramName="title" } );
		}
		if ( !StructKeyExists( params, "description" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Description: ", required=false, paramName="description" } );
		}

		if ( ArrayLen( userInputPrompts ) ) {
			return {
				  echo        = Chr(10) & "[[b;white;]:: Welcome to the new extension command wizard]" & Chr(10) & Chr(10)
				, inputPrompt = userInputPrompts
				, method      = "new"
				, params      = params
			};
		}

		var filesCreated = [];
		try {
			filesCreated = scaffoldingService.scaffoldExtension(
				  id          = params.id
				, title       = params.title
				, description = params.description
			);
		} catch ( any e ) {
			return Chr(10) & "[[b;red;]Error creating extension:] [[b;white;]#e.message#]" & Chr(10);
		}

		var msg = Chr(10) & "[[b;white;]Your extension has been created!] The following files were created:" & Chr(10) & Chr(10);
		for( var file in filesCreated ) {
			msg &= "    " & file & Chr(10);
		}

		return msg;
	}

	private function configform( event, rc, prc ) {
		var params           = jsonRpc2Plugin.getRequestParams();
		var userInputPrompts = [];

		if ( !StructKeyExists( params, "id" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Form ID (category): ", required=true, paramName="id" } );
		}
		if ( !StructKeyExists( params, "fields" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Config fields, e.g. 'title,max_items,feed_url': ", required=true, paramName="fields"} );
		}
		if ( !StructKeyExists( params, "name" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Friendly name: ", required=true, paramName="name"} );
		}
		if ( !StructKeyExists( params, "description" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Description: ", required=false, paramName="description"} );
		}
		if ( !StructKeyExists( params, "icon" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Icon class, we use font-awesome 4: ", required=false, default="fa-cogs", paramName="icon"} );
		}
		if ( !StructKeyExists( params, "extension" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Extension name, leave blank for no extension: ", required=false, paramName="extension"} );
		}

		if ( ArrayLen( userInputPrompts ) ) {
			return {
				  echo        = Chr(10) & "[[b;white;]:: Welcome to the new system config form wizard]" & Chr(10) & Chr(10)
				, inputPrompt = userInputPrompts
				, method      = "new"
				, params      = params
			};
		}

		var filesCreated = [];
		try {
			filesCreated = scaffoldingService.scaffoldSystemConfigForm( argumentCollection = params );
		} catch ( any e ) {
			return Chr(10) & "[[b;red;]Error creating system config form:] [[b;white;]#e.message#]" & Chr(10);
		}

		var msg = Chr(10) & "[[b;white;]Your system config form has been created!] The following files were created:" & Chr(10) & Chr(10);
		for( var file in filesCreated ) {
			msg &= "    " & file & Chr(10);
		}

		return msg;
	}

	private function emailTemplate( event, rc, prc ) {
		var params           = jsonRpc2Plugin.getRequestParams();
		var userInputPrompts = [];

		if ( !StructKeyExists( params, "id" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Template ID: ", required=true, paramName="id" } );
		}
		if ( !StructKeyExists( params, "extension" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Extension name, leave blank for no extension: ", required=false, paramName="extension"} );
		}

		if ( ArrayLen( userInputPrompts ) ) {
			return {
				  echo        = Chr(10) & "[[b;white;]:: Welcome to the new email template wizard]" & Chr(10) & Chr(10)
				, inputPrompt = userInputPrompts
				, method      = "new"
				, params      = params
			};
		}

		var filesCreated = [];
		try {
			filesCreated = scaffoldingService.scaffoldEmailTemplate( argumentCollection = params );
		} catch ( any e ) {
			return Chr(10) & "[[b;red;]Error creating email template:] [[b;white;]#e.message#]" & Chr(10);
		}

		var msg = Chr(10) & "[[b;white;]Your email template has been created!] The following files were created:" & Chr(10) & Chr(10);
		for( var file in filesCreated ) {
			msg &= "    " & file & Chr(10);
		}

		return msg;
	}

	private function formcontrol( event, rc, prc ) {
		var params           = jsonRpc2Plugin.getRequestParams();
		var userInputPrompts = [];

		if ( !StructKeyExists( params, "id" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Form control ID: ", required=true, paramName="id" } );
		}
		if ( !StructKeyExists( params, "createHandler" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Create handler?", required=true, default="N", paramName="createHandler", validityRegex="^[YyNn]$" } );
		}
		if ( !StructKeyExists( params, "contexts" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Contexts (e.g. index,website):", required=false, default="index", paramName="contexts" } );
		}
		if ( !StructKeyExists( params, "extension" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Extension name, leave blank for no extension: ", required=false, paramName="extension"} );
		}


		if ( ArrayLen( userInputPrompts ) ) {
			return {
				  echo        = Chr(10) & "[[b;white;]:: Welcome to the new form control wizard]" & Chr(10) & Chr(10)
				, inputPrompt = userInputPrompts
				, method      = "new"
				, params      = params
			};
		}

		var filesCreated = [];
		try {
			filesCreated = scaffoldingService.scaffoldFormControl(
				  id            = params.id
				, contexts      = ListToArray( params.contexts )
				, createHandler = ( params.createHandler == "y" ? true : false )
				, extension     = params.extension
			);
		} catch ( any e ) {
			return Chr(10) & "[[b;red;]Error creating form control:] [[b;white;]#e.message#]" & Chr(10);
		}

		var msg = Chr(10) & "[[b;white;]Your form control has been created!] The following files were created:" & Chr(10) & Chr(10);
		for( var file in filesCreated ) {
			msg &= "    " & file & Chr(10);
		}

		return msg;
	}

	private function ruleexpression( event, rc, prc ) {
		var params           = jsonRpc2Plugin.getRequestParams();
		var userInputPrompts = [];

		if ( !StructKeyExists( params, "id" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Expression ID (e.g. 'loggedIn'): ", required=true, paramName="id" } );
		}
		if ( !StructKeyExists( params, "label" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Expression label (e.g. 'User is logged in'): ", required=true, paramName="label" } );
		}
		if ( !StructKeyExists( params, "text" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Expression text (e.g. 'User {_is} logged in'): ", required=true, paramName="text" } );
		}
		if ( !StructKeyExists( params, "context" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Context (e.g. webrequest):", required=false, default="webrequest", paramName="context" } );
		}
		if ( !StructKeyExists( params, "extension" ) ) {
			ArrayAppend( userInputPrompts, { prompt="Extension name, leave blank for no extension: ", required=false, paramName="extension"} );
		}


		if ( ArrayLen( userInputPrompts ) ) {
			return {
				  echo        = Chr(10) & "[[b;white;]:: Welcome to the new rule expression wizard]" & Chr(10) & Chr(10)
				, inputPrompt = userInputPrompts
				, method      = "new"
				, params      = params
			};
		}

		var filesCreated = [];
		try {
			filesCreated = scaffoldingService.scaffoldRuleExpression(
				  id        = params.id
				, label     = params.label
				, text      = params.text
				, context   = params.context
				, extension = params.extension
			);
		} catch ( any e ) {
			return Chr(10) & "[[b;red;]Error creating rule expression:] [[b;white;]#e.message#]" & Chr(10);
		}

		var msg = Chr(10) & "[[b;white;]Your rule expression has been created!] The following files were created:" & Chr(10) & Chr(10);
		for( var file in filesCreated ) {
			msg &= "    " & file & Chr(10);
		}

		return msg;
	}

	private function terminalCommand( event, rc, prc ) {
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

		var filesCreated = [];
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
		for( var file in filesCreated ) {
			msg &= "    " & file & Chr(10);
		}

		return msg;
	}
}