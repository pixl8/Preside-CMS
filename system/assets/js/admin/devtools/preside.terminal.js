window.presideTerminal = ( function( $ ){
	var rpcEndpoint = buildAdminLink( "devtools.terminal" )
	  , prompt               = "preside-terminal> "
	  , promptStack          = []
	  , collectedUserInput   = {}
	  , inputCollectedMethod = ""
      , inputCollectedParams = {}
      , terminalToggleKey    = parseInt( typeof cfrequest.devConsoleToggleKeyCode === "undefined" ? 96 : cfrequest.devConsoleToggleKeyCode )
      , availableCommands    = { help : "Displays this help message", clear : "Clears the console", exit : "Quits the console" }
	  , $terminal, terminal, interpreter, config, isEnabled, disableTerminal, toggleTerminal, initTerminal, isInitialized, responseProcessor, resetPrompt, ajaxError, setupPromptStack, processPromptInput, setNextPrompt, sendCollectedUserInput, sendCommand, popPromptFromStack, echoHelp, escapePrompt;

	initTerminal = function( callback ){
		$.jrpc( rpcEndpoint, "listMethods", {systemcall:true}, function(json){
			var autoCompleteCommands = [];

			availableCommands = $.extend( availableCommands, json.result || {} );
			for( cmd in availableCommands ){
				autoCompleteCommands.push( cmd );
			}

			$terminal = $('<div id="preside-terminal"></div>').appendTo( $( "body" ) );

			config = {
				  prompt               : prompt
				, greetings            : '[[b;white;]:: Welcome to Preside developer console! Type "help" for commands.\n\n]'
				, completion           : autoCompleteCommands
				, ignoreSystemDescribe : true
				, exit                 : false
				, processRPCResponse   : responseProcessor
				, historySize          : 20
				, keypress             : function( e ){ if( e.which === terminalToggleKey ){ return false; } }
				, onClear              : function( terminal ){ terminal.echo( '[[b;white;]:: Welcome to Preside developer console! Type "help" for commands.\n\n]' ); }
			};

			$terminal.terminal( interpreter, config );

			terminal = $terminal.data( 'terminal' );
			$('body').keydown( "ctrl+c", escapePrompt );

			callback();
		} );
	};

	interpreter = function( command ){
		if ( promptStack instanceof Array && promptStack.length ) {
			return processPromptInput( command );
		}

		command = $.trim( command );

		if ( command === '' ) {
			return;
		} else if ( command === 'exit' ) {
 			return toggleTerminal();
		} else if ( command === 'help' ) {
			return echoHelp();
		}

		var splitCommand = command.split( ' ' )
		  , method       = splitCommand[0]
		  , params       = { commandLineArgs : $.terminal.parseArguments( splitCommand.splice(1).join( ' ' ) ) }; // for now do this, we probably want to do our own smarter processing here

		sendCommand( method, params );
	};

	sendCommand = function( method, params ) {
		terminal.pause();
		$.jrpc( rpcEndpoint, method, params, function( json ) {
			if (!json.error) {
				responseProcessor( json.result );
			} else {
				terminal.error( '&#91;RPC&#93; ' + json.error.message );
			}
			terminal.resume();
		}, ajaxError );
	};

	responseProcessor = function( result ){
		if ( typeof result === 'string') {
			terminal.echo( result );
			resetPrompt();
		} else {
			if ( typeof result.echo === "string" ) {
				terminal.echo( result.echo );
			}
			if ( typeof result.inputPrompt !== "undefined" ) {
				setupPromptStack( result.inputPrompt, result.method, result.params );
			} else {
				resetPrompt();
			}
		}
	};

	isInitialized = function(){
		return typeof terminal !== "undefined";
	};

	toggleTerminal = function(){
		var toggle = function(){
			$( ":focus" ).blur();
			$terminal.slideToggle( "fast", function(){
				terminal.focus( $(this).is( ":visible" ) );
			} );
		};

		if ( !isInitialized() ) {
			initTerminal( toggle );
		} else {
			toggle();
		}
	};

	isEnabled = function(){
		return isInitialized() && terminal.enabled();
	};
	disableTerminal = function(){
		isInitialized() && terminal.disable();
	};

	resetPrompt = function(){
		terminal.set_prompt( prompt );
	};

	setupPromptStack = function( prompts, method, params ){
		promptStack          = ( prompts instanceof Array ) ? prompts : [ prompts ];
		inputCollectedMethod = method;
		inputCollectedParams = params;

		setNextPrompt();
	};

	processPromptInput = function( input ) {
		var currentPrompt = promptStack[0];

		input = $.trim( input );
		if ( !input.length ) {
			if ( typeof currentPrompt[ "default" ] === "string" ) {
				input = currentPrompt[ "default" ];
			} else if ( typeof currentPrompt.required === "boolean" && currentPrompt.required ) {
				return;
			}
		}

		if ( typeof currentPrompt.validityRegex === "string" && input.match( new RegExp( currentPrompt.validityRegex ) ) === null ) {
			return;
		}

		collectedUserInput[ currentPrompt.paramName || "unknown" ] = input;
		popPromptFromStack();


		if ( !promptStack.length ) {
			return sendCollectedUserInput();
		}

		return setNextPrompt();
	};

	setNextPrompt = function(){
		var currentPrompt, prmpt;

		while( promptStack.length ){
			currentPrompt = promptStack[0];
			if ( typeof currentPrompt.prompt === "string" ) {
				prmpt = currentPrompt.prompt;

				if ( typeof currentPrompt["default"] === "string" ) {
					prmpt += " (" + currentPrompt[ 'default' ] + ")";
				}

				terminal.set_prompt( prmpt );
				break;
			} else {
				popPromptFromStack();
			}
		}
	};

	popPromptFromStack = function(){
		promptStack = promptStack.splice(1);
	};

	sendCollectedUserInput = function(){
		var params = collectedUserInput
		  , param;

		if ( typeof inputCollectedParams === "object" ) {
			for( param in inputCollectedParams ) {
				params[ param ] = inputCollectedParams[ param ];
			}
		}

		sendCommand( inputCollectedMethod, params );
	}

	echoHelp = function(){
		var helpText = "\n[[b;white;]Available commands:]\n\n"
		  , padSpaces = function( count ){ return new Array( count + 1 ).join( " " ); };

		for( cmd in availableCommands ) {
			helpText += "    [[b;white;]" + cmd + padSpaces( 15 - cmd.length ) + ":] " + availableCommands[cmd] + "\n";
		}

		helpText += "\n";

		terminal.echo( helpText );
	};

	ajaxError = function(xhr, status, error) {
		terminal.resume();
		if ( status !== 'abort' ) {
			terminal.error( '&#91;AJAX&#93; ' + status + ' - ' +
			'Server response is: \n' + xhr.responseText );
		}
	};

	escapePrompt = function(){
		if ( isEnabled ) {
			promptStack = [];
			terminal.echo( "[[b;white;]ctrl-c detected. Aborting]\n" );
			resetPrompt();
		}
	};

	return {
		  enabled : isEnabled
		, disable : disableTerminal
		, toggle  : toggleTerminal
	};
} )( presideJQuery );