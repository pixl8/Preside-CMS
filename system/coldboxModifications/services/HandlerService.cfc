component extends="coldbox.system.web.services.HandlerService" {

	variables.handlerBeans = {};

	public void function registerHandlers() {
		var appMapping                   = "/" & controller.getSetting( "appMapping" ).reReplace( "^/", "" );
		var appMappingPath               = controller.getSetting( "appMappingPath" );
		var handlersPath                 = controller.getSetting( "HandlersPath" );
		var handlersExternalLocationPath = controller.getSetting( "HandlersExternalLocationPath" );
		var handlersInvocationPath       = controller.getSetting("HandlersInvocationPath");
		var handlersExternalLocation     = controller.getSetting("HandlersExternalLocation");
		var activeExtensions             = controller.getSetting( name="activeExtensions", defaultValue=[] );
		var handlerMappings              = [];
		var siteTemplateHandlerMappings  = {};

		ArrayAppend( handlerMappings, { invocationPath=handlersInvocationPath, handlers=getHandlerListing( handlersPath, handlersInvocationPath ) } );

		_addSiteTemplateHandlerMappings( "#appMapping#/site-templates/", "#appMappingPath#.site-templates", siteTemplateHandlerMappings );
		for( var i=activeExtensions.len(); i>0; i-- ) {
			var ext = activeExtensions[ i ];
			var extensionHandlersPath   = ExpandPath( "#appMapping#/extensions/#ext.name#/handlers" );
			var extensionInvocationPath = "#appMappingPath#.extensions.#ext.name#.handlers";

			ArrayAppend( handlerMappings, { invocationPath=extensionInvocationPath, handlers=getHandlerListing( extensionHandlersPath, extensionInvocationPath ) } );

			_addSiteTemplateHandlerMappings( "#appMapping#/extensions/#ext.name#/site-templates/", "#appMappingPath#.extensions.#ext.name#.site-templates", siteTemplateHandlerMappings );
		}

		variables.registeredHandlers = {};
		for( var i=1; i<=handlerMappings.len(); i++ ) {
			for( var handlerName in _listHandlerNames( handlerMappings[i].handlers ).listToArray() ) {
				variables.registeredHandlers[ handlerName ] = 1;
			}
		}
		variables.registeredHandlers = StructKeyList( variables.registeredHandlers );
		controller.setSetting( name="RegisteredHandlers", value=variables.registeredHandlers );

		ArrayAppend( handlerMappings, { invocationPath=handlersExternalLocation, handlers=getHandlerListing( HandlersExternalLocationPath, handlersExternalLocation ) } );
		variables.registeredExternalHandlers = _listHandlerNames( handlerMappings[handlerMappings.len()].handlers );
		controller.setSetting( name="RegisteredExternalHandlers", value=variables.registeredExternalHandlers );

		variables.handlerMappings             = handlerMappings;
		variables.siteTemplateHandlerMappings = siteTemplateHandlerMappings;
	}

	public array function getHandlerListing( required string directory, string invocationPath ) {
		var i                = 1;
		var thisAbsolutePath = "";
		var cleanHandler     = "";
		var fileArray        = ArrayNew(1);
		var files            = DirectoryList( arguments.directory, true, "query", "*.cfc" );
		var actions          = "";

		// Convert windows \ to java /
		arguments.directory = replace(arguments.directory,"\","/","all");

		// Iterate, clean and register
		for (i=1; i lte files.recordcount; i=i+1 ){

			thisAbsolutePath = replace(files.directory[i],"\","/","all") & "/";
			cleanHandler = replacenocase(thisAbsolutePath,arguments.directory,"","all") & files.name[i];

			// Clean OS separators to dot notation.
			cleanHandler = removeChars(replacenocase(cleanHandler,"/",".","all"),1,1);

			//Clean Extension
			cleanHandler = controller.getUtil().ripExtension(cleanhandler);

			//Add data to array
			actions = _getCfcMethods( getComponentMetaData( ListAppend( arguments.invocationPath, cleanHandler, "." ) ) );

			ArrayAppend( fileArray , { name=cleanHandler, actions=Duplicate( actions ) } );
		}

		return fileArray;
	}

	public any function getHandlerBean( required string event ) {
		var currentSite = controller.getRequestContext().getSite();
		var beanKey     = arguments.event & ( currentSite.id ?: "" );

		if ( StructKeyExists( variables.handlerBeans, beanKey ) ) {
			return variables.handlerBeans[ beanKey ];
		}

		var handlerBean     = _newHandlerBean( variables.handlersInvocationPath );
		var handlerReceived = ListLast( ReReplace( arguments.event, "\.[^.]*$", "" ), ":" );
		var methodReceived  = ListLast( arguments.event, "." );
		var isModuleCall    = Find( ":", arguments.event );
		var moduleSettings  = variables.modules;
		var handlerIndex    = 0;
		var moduleReceived  = "";

		if( !isModuleCall ){
			if ( Len( Trim( currentSite.template ?: "" ) ) && StructKeyExists( variables.siteTemplateHandlerMappings, currentSite.template ) ) {
				for ( var handlerSource in variables.siteTemplateHandlerMappings[ currentSite.template ] ) {
					handlerIndex = _getHandlerIndex( handlerSource.handlers, handlerReceived, methodReceived );

					if ( handlerIndex ) {
						variables.handlerBeans[ beanKey ] = handlerBean
							.setInvocationPath( handlerSource.invocationPath                )
							.setHandler       ( handlerSource.handlers[ handlerIndex ].name )
							.setMethod        ( methodReceived                              );

						return variables.handlerBeans[ beanKey ];
					}
				}
			}

			for ( var handlerSource in variables.handlerMappings ) {
				handlerIndex = _getHandlerIndex( handlerSource.handlers, handlerReceived, methodReceived );

				if ( handlerIndex ) {
					variables.handlerBeans[ beanKey ] = handlerBean
						.setInvocationPath( handlerSource.invocationPath                )
						.setHandler       ( handlerSource.handlers[ handlerIndex ].name )
						.setMethod        ( methodReceived                              );

					return variables.handlerBeans[ beanKey ];
				}
			}
		} else {
			moduleReceived = listFirst( arguments.event, ":" );

			if ( StructKeyExists( moduleSettings, moduleReceived ) ) {
				handlerIndex = ListFindNoCase( moduleSettings[ moduleReceived ].registeredHandlers, handlerReceived );
				if ( handlerIndex ) {
					variables.handlerBeans[ beanKey ] = handlerBean
						.setInvocationPath( moduleSettings[ moduleReceived ].handlerInvocationPath )
						.setHandler( ListgetAt( moduleSettings[ moduleReceived ].registeredHandlers, handlerIndex ) )
						.setMethod( methodReceived )
						.setModule( moduleReceived );

					return variables.handlerBeans[ beanKey ];
				}
			}

			variables.log.error( "Invalid Module Event Called: #arguments.event#. The module: #moduleReceived# is not valid. Valid Modules are: #structKeyList(moduleSettings)#" );
		}

		// Do View Dispatch Check Procedures
		if ( isViewDispatch( arguments.event, handlerBean ) ) {
			variables.handlerBeans[ beanKey ] = handlerBean;
			return handlerBean;
		}

		// Run invalid event procedures, handler not found
		invalidEvent( arguments.event, handlerBean );

		// If we get here, then invalid event handler is active and we need to
		// return an event handler bean that matches it
		return getHandlerBean( handlerBean.getFullEvent() );
	}

	public any function getHandler( required any ehBean, required any requestContext ) {
		try {
			return _getHandler( argumentCollection=arguments );
		} catch( expression e ) {
			if ( ( e.message ?: "" ) contains "has no accessible Member with name" ) {
				invalidEvent( arguments.ehBean.getFullEvent(), arguments.ehBean );

				return getHandler( getHandlerBean( arguments.ehBean.getFullEvent()), arguments.requestContext );
			} else {
				rethrow;
			}
		}
	}

	public array function listHandlers( string thatStartWith="" ) {
		var handlers = {};
		var startWithLen = Len( arguments.thatStartWith );

		for( var source in variables.handlerMappings ) {
			for( var handler in  source.handlers ){
				if ( !startWithLen || Left( handler.name, startWithLen ) == arguments.thatStartWith ) {
					handlers[ handler.name ] = 0;
				}
			}
		}

		handlers = StructKeyArray( handlers );
		handlers.sort( "textnocase" );

		return handlers;
	}

	public void function invalidEvent(){
		try {
			super.invalidEvent( argumentCollection=arguments );
		} catch( any e ) {
			rethrow;
		} finally {
			controller.getRequestService().getContext().setHTTPHeader(
				  statusCode = 200
				, statusText = "OK"
			);
		}
	}

// helpers
	private void function _addSiteTemplateHandlerMappings( required string siteTemplatesPath, required string siteTemplatesInvocationPath, required struct existingMappings ) {
		if ( !DirectoryExists( arguments.siteTemplatesPath ) ) {
			return;
		}

		for( var subDir in DirectoryList( arguments.siteTemplatesPath, false, "query" ) ) {
			if ( subDir.type == "Dir" ) {
				var handlersDir    = arguments.siteTemplatesPath & "/#subDir.name#/handlers";
				var invocationPath = arguments.siteTemplatesInvocationPath & ".#subDir.name#.handlers"

				if ( DirectoryExists( handlersDir ) ) {
					arguments.existingMappings[ subDir.name ] = arguments.existingMappings[ subDir.name ] ?: [];
					arguments.existingMappings[ subDir.name ].append( { invocationPath=invocationPath, handlers=getHandlerListing( ExpandPath( handlersDir ), invocationPath ) } );
				}
			}
		}
	}

	private array function _getCfcMethods( required struct meta ) {
		var methods = {};

		if ( ( arguments.meta.extends ?: {} ).count() ) {
			_getCfcMethods( arguments.meta.extends ).each( function( method ){
				methods[ method ] = true;
			} );
		}
		var metaMethods = arguments.meta.functions ?: [];
		for( var method in metaMethods ) {
			methods[ method.name ] = true;
		}

		return methods.keyArray();
	}

	private string function _listHandlerNames( required array handlers ) {
		var names = [];

		for( var handler in arguments.handlers ){
			names.append( handler.name );
		}

		return names.toList();
	}

	private numeric function _getHandlerIndex( required array handlers, required string handlerName, required string actionName ) {
		for( var i=1; i <= arguments.handlers.len(); i++ ){
			if ( arguments.handlers[i].name == arguments.handlerName && arguments.handlers[i].actions.findNoCase( arguments.actionName ) ) {
				return i;
			}
		}
		return 0;
	}

	private any function _newHandlerBean( required string invocationPath ) {
		if ( !StructKeyExists( variables, "_ehBean" ) ) {
			variables._ehBean = new preside.system.coldboxModifications.services.EventHandlerBean();
		}

		var cloned = Duplicate( variables._ehBean, false );
		return cloned.setInvocationPath( arguments.invocationPath );
	}

	private any function _getHandler( required ehBean, required requestContext ){
		var oRequestContext = arguments.requestContext;
		var oEventURLFacade = variables.templateCache.getEventURLFacade();
		// Create Runnable Object via WireBox
		var oEventHandler = newHandler( arguments.ehBean.getRunnable() );

		/* ::::::::::::::::::::::::::::::::::::::::: EVENT METHOD TESTING :::::::::::::::::::::::::::::::::::::::::::: */

		// Does requested method/action of execution exist in handler?
		if( NOT oEventHandler._actionExists( arguments.ehBean.getMethod() ) ){

			// Check if the handler has an onMissingAction() method, virtual Events
			if( oEventHandler._actionExists( "onMissingAction" ) ){
				// Override the method of execution
				arguments.ehBean.setMissingAction( arguments.ehBean.getMethod() );
				// Let's go execute our missing action
				return oEventHandler;
			}

			// Test for Implicit View Dispatch
			if( controller.getSetting( "ImplicitViews" ) AND
				isViewDispatch( arguments.ehBean.getFullEvent(), arguments.ehBean )
			){
				return oEventHandler;
			}

			// Invalid Event procedures
			invalidEvent( arguments.ehBean.getFullEvent(), arguments.ehBean );

			// If we get here, then the invalid event kicked in and exists, else an exception is thrown
			// Go retrieve the handler that will handle the invalid event so it can execute.
			return getHandler(
				getHandlerBean( arguments.ehBean.getFullEvent() ),
				oRequestContext
			);

		} //method check finalized.

		// Store metadata in execution bean
		if ( !arguments.ehBean.getMetaDataIsSet() ) {
			arguments.ehBean
				.setActionMetadata( oEventHandler._actionMetadata( arguments.ehBean.getMethod() ) )
				.setHandlerMetadata( getMetadata( oEventHandler ) )
				.setMetaDataIsSet( true );
		}

		/* ::::::::::::::::::::::::::::::::::::::::: EVENT CACHING :::::::::::::::::::::::::::::::::::::::::::: */

		// Event Caching Routines, if using caching, NOT a private event and we are executing the main event
		if (
			variables.eventCaching AND
			!arguments.ehBean.getIsPrivate() AND
			arguments.ehBean.getFullEvent() EQ oRequestContext.getCurrentEvent()
		){

			// Get event action caching metadata
			var eventDictionaryEntry = getEventCachingMetadata( arguments.ehBean, oEventHandler );

			// Do we need to cache this event's output after it executes??
			if ( eventDictionaryEntry.cacheable ){
				// Create caching data structure according to MD, as the cache key can be dynamic by execution.
				var eventCachingData = {};
				structAppend( eventCachingData, eventDictionaryEntry, true );

				// Create the Cache Key to save
				eventCachingData.cacheKey = oEventURLFacade.buildEventKey(
					keySuffix 		= eventDictionaryEntry.suffix,
					targetEvent 	= arguments.ehBean.getFullEvent(),
					targetContext 	= oRequestContext
				);

				// Event is cacheable and we need to flag it so the Renderer caches it
				oRequestContext.setEventCacheableEntry( eventCachingData );

			} //end if md says that this event is cacheable

		} //end if event caching.

		//return the tested and validated event handler
		return oEventHandler;
	}
}