component extends="coldbox.system.web.services.HandlerService" output=false {

	public void function registerHandlers() output=false {
		var handlersPath                 = controller.getSetting( "HandlersPath" );
		var handlersExternalLocationPath = controller.getSetting( "HandlersExternalLocationPath" );
		var handlersInvocationPath       = controller.getSetting("HandlersInvocationPath");
		var handlersExternalLocation     = controller.getSetting("HandlersExternalLocation");
		var activeExtensions             = controller.getSetting( name="activeExtensions", defaultValue=[] );
		var handlerMappings              = [];

		ArrayAppend( handlerMappings, { invocationPath=handlersInvocationPath, handlers=getHandlerListing( handlersPath ) } );
		controller.setSetting( name="RegisteredHandlers", value=ArrayToList( handlerMappings[1].handlers ) );

		for( var ext in activeExtensions ) {
			var extensionHandlersPath   = ExpandPath( "/app/extensions/#ext.name#/handlers" );
			var extensionInvocationPath = "app.extensions.#ext.name#.handlers";

			ArrayAppend( handlerMappings, { invocationPath=extensionInvocationPath, handlers=getHandlerListing( extensionHandlersPath ) } );
		}

		ArrayAppend( handlerMappings, { invocationPath=handlersExternalLocation, handlers=getHandlerListing( HandlersExternalLocationPath ) } );
		controller.setSetting( name="RegisteredExternalHandlers", value=ArrayToList( handlerMappings[ handlerMappings.len() ].handlers ) );

		instance.handlerMappings = handlerMappings;
	}

	public any function getRegisteredHandler( required string event ) output=false {
		var handlerBean     = new coldbox.system.web.context.EventHandlerBean( instance.handlersInvocationPath );
		var handlerReceived = ListLast( ReReplace( arguments.event, "\.[^.]*$", "" ), ":" );
		var methodReceived  = ListLast( arguments.event, "." );
		var isModuleCall    = Find( ":", arguments.event );
		var moduleSettings  = instance.modules;
		var handlerIndex    = 0;
		var moduleReceived  = "";

		if( !isModuleCall ){
			for ( var handlerSource in instance.handlerMappings ) {
				handlerIndex = ArrayFindNoCase( handlerSource.handlers, handlerReceived );

				if ( handlerIndex ) {
					return handlerBean
						.setInvocationPath( handlerSource.invocationPath           )
						.setHandler       ( handlerSource.handlers[ handlerIndex ] )
						.setMethod        ( methodReceived                         );
				}
			}
		} else {
			moduleReceived = listFirst( arguments.event, ":" );

			if ( StructKeyExists( moduleSettings, moduleReceived ) ) {
				handlerIndex = ListFindNoCase( moduleSettings[ moduleReceived ].registeredHandlers, handlerReceived );
				if ( handlerIndex ) {
					return handlerBean
						.setInvocationPath( moduleSettings[ moduleReceived ].handlerInvocationPath )
						.setHandler( ListgetAt( moduleSettings[ moduleReceived ].registeredHandlers, handlerIndex ) )
						.setMethod( methodReceived )
						.setModule( moduleReceived );
				}
			}

			controller.getPlugin("Logger").error( "Invalid Module Event Called: #arguments.event#. The module: #moduleReceived# is not valid. Valid Modules are: #structKeyList(moduleSettings)#" );
		}

		// Do View Dispatch Check Procedures
		if ( isViewDispatch( arguments.event, handlerBean ) ) {
			return handlerBean;
		}

		// Run invalid event procedures, handler not found
		invalidEvent( arguments.event, handlerBean );

		// If we get here, then invalid event handler is active and we need to
		// return an event handler bean that matches it
		return getRegisteredHandler( handlerBean.getFullEvent() );
	}

	public array function listHandlers( string thatStartWith="" ) output=false {
		var handlers = {};
		var startWithLen = Len( arguments.thatStartWith );

		for( var source in instance.handlerMappings ) {
			for( var handler in  source.handlers ){
				if ( !startWithLen || Left( handler, startWithLen ) == arguments.thatStartWith ) {
					handlers[ handler ] = 0;
				}
			}
		}

		handlers = StructKeyArray( handlers );
		handlers.sort( "textnocase" );

		return handlers;
	}
}