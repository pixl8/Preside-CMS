component extends="coldbox.system.web.services.HandlerService" output=false {

	public void function registerHandlers() output=false {
		var handlersPath                 = controller.getSetting( "HandlersPath" );
		var handlersExternalLocationPath = controller.getSetting( "HandlersExternalLocationPath" );
		var handlersInvocationPath       = controller.getSetting("HandlersInvocationPath");
		var handlersExternalLocation     = controller.getSetting("HandlersExternalLocation");
		var activeExtensions             = controller.getSetting( name="activeExtensions", defaultValue=[] );
		var handlerMappings              = [];
		var siteTemplateHandlerMappings  = {};

		ArrayAppend( handlerMappings, { invocationPath=handlersInvocationPath, handlers=getHandlerListing( handlersPath ) } );
		controller.setSetting( name="RegisteredHandlers", value=ArrayToList( handlerMappings[1].handlers ) );

		_addSiteTemplateHandlerMappings( "/app/site-templates/", "app.site-templates", siteTemplateHandlerMappings );

		for( var ext in activeExtensions ) {
			var extensionHandlersPath   = ExpandPath( "/app/extensions/#ext.name#/handlers" );
			var extensionInvocationPath = "app.extensions.#ext.name#.handlers";

			ArrayAppend( handlerMappings, { invocationPath=extensionInvocationPath, handlers=getHandlerListing( extensionHandlersPath ) } );
			_addSiteTemplateHandlerMappings( "/app/extensions/#ext.name#/site-templates/", "app.extensions.#ext.name#.site-templates", siteTemplateHandlerMappings );
		}

		ArrayAppend( handlerMappings, { invocationPath=handlersExternalLocation, handlers=getHandlerListing( HandlersExternalLocationPath ) } );
		controller.setSetting( name="RegisteredExternalHandlers", value=ArrayToList( handlerMappings[ handlerMappings.len() ].handlers ) );

		instance.handlerMappings             = handlerMappings;
		instance.siteTemplateHandlerMappings = siteTemplateHandlerMappings;
	}

	public any function getRegisteredHandler( required string event ) output=false {
		var handlerBean     = new coldbox.system.web.context.EventHandlerBean( instance.handlersInvocationPath );
		var handlerReceived = ListLast( ReReplace( arguments.event, "\.[^.]*$", "" ), ":" );
		var methodReceived  = ListLast( arguments.event, "." );
		var isModuleCall    = Find( ":", arguments.event );
		var moduleSettings  = instance.modules;
		var handlerIndex    = 0;
		var moduleReceived  = "";
		var currentSite     = controller.getRequestContext().getSite();

		if( !isModuleCall ){

			if ( Len( Trim( currentSite.template ?: "" ) ) && instance.siteTemplateHandlerMappings.keyExists( currentSite.template ) ) {
				for ( var handlerSource in instance.siteTemplateHandlerMappings[ currentSite.template ] ) {
					handlerIndex = ArrayFindNoCase( handlerSource.handlers, handlerReceived );

					if ( handlerIndex ) {
						return handlerBean
							.setInvocationPath( handlerSource.invocationPath           )
							.setHandler       ( handlerSource.handlers[ handlerIndex ] )
							.setMethod        ( methodReceived                         );
					}
				}
			}

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

// hELPERS
	private void function _addSiteTemplateHandlerMappings( required string siteTemplatesPath, required string siteTemplatesInvocationPath, required struct existingMappings ) output=false {
		if ( !DirectoryExists( arguments.siteTemplatesPath ) ) {
			return;
		}

		for( var subDir in DirectoryList( arguments.siteTemplatesPath, false, "query" ) ) {
			if ( subDir.type == "Dir" ) {
				var handlersDir    = arguments.siteTemplatesPath & "/#subDir.name#/handlers";
				var invocationPath = arguments.siteTemplatesInvocationPath & ".#subDir.name#.handlers"

				if ( DirectoryExists( handlersDir ) ) {
					arguments.existingMappings[ subDir.name ] = arguments.existingMappings[ subDir.name ] ?: [];
					arguments.existingMappings[ subDir.name ].append( { invocationPath=invocationPath, handlers=getHandlerListing( ExpandPath( handlersDir ) ) } );
				}
			}
		}
	}
}