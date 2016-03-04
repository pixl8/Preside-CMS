component extends="coldbox.system.Coldbox" output="false" {

	public void function loadColdbox() output=false {
		var appKey     = super.locateAppKey();
		var controller = new Controller( COLDBOX_APP_ROOT_PATH, appKey );

		controller.getLoaderService().loadApplication( COLDBOX_CONFIG_FILE, COLDBOX_APP_MAPPING );

		if ( Len( controller.getSetting( "ApplicationStartHandler" ) ) ) {
			controller.runEvent( controller.getSetting( "ApplicationStartHandler" ), true );
		}

		StructDelete( application, appKey );
		application[ appKey ] = controller;
	}

	public boolean function onRequestStart( required string targetPage ) output=true {
		reloadChecks();

		if ( ReFindNoCase( 'index\.cfm$', arguments.targetPage ) ) {
			var content = "";

			savecontent variable="content" {
				processColdBoxRequest();
			}

			content = Trim( content );

			if ( Len( content ) ) {
				content reset=true;WriteOutput( content );return true;
			}
		}

		return true;
	}

	public any function getController() output=false {
		return application[ locateAppKey() ] ?: NullValue();
	}

	public void function processColdBoxRequest() output=true {
		var cbController       = getController();
		var event              = 0;
		var exceptionService   = 0;
		var exceptionBean      = 0;
		var renderedContent    = "";
		var eventCacheEntry    = 0;
		var interceptorData    = {}
		var renderData         = {}
		var refResults         = {}
		var debugPanel         = "";
		var interceptorService = "";


		// Setup Local Vars
		interceptorService = cbController.getInterceptorService();
		templateCache      = cbController.getColdboxOCM( "template" );

		// set request time
		request.fwExecTime = getTickCount();

		try {
			// Create Request Context & Capture Request
			event = cbController.getRequestService().requestCapture();

			// Debugging Monitors & Commands Check
			if ( cbController.getDebuggerService().getDebugMode() ) {

				// ColdBox Command Executions
				coldboxCommands(cbController,event);

				// Debug Panel rendering
				debugPanel = event.getValue("debugPanel","");
				switch( debugPanel ) {
					case "profiler":
						WriteOutput( cbController.getDebuggerService().renderProfiler() );
					break;
					case "cache,cacheReport,cacheContentReport,cacheViewer":
						module template="/coldbox/system/cache/report/monitor.cfm" cacheFactory=cbController.getCacheBox();
					break;
				}

				// Stop Processing, we are rendering a debugger panel
				if ( len(debugPanel) ) {
					setting showdebugoutput=false;
					return;
				}
			}

			// Execute preProcess Interception
			interceptorService.processState( "preProcess" );

			// IF Found in config, run onRequestStart Handler
			if ( Len( cbController.getSetting("RequestStartHandler" ) ) ) {
				cbController.runEvent( cbController.getSetting( "RequestStartHandler" ), true );
			}

			// Before Any Execution, do we have cached content to deliver
			if ( StructKeyExists( event.getEventCacheableEntry(), "cachekey" ) ) {
				refResults.eventCaching = templateCache.get( event.getEventCacheableEntry().cacheKey );
			}
			if ( StructKeyExists( refResults, "eventCaching" ) ) {
				// Is this a renderdata type?
				if ( refResults.eventCaching.renderData ) {
					renderDataSetup( argumentCollection=refResults.eventCaching );
					event.showDebugPanel( false );
				}
				// Render Content as binary or just output
				if ( refResults.eventCaching.isBinary ) {
					content type=refResults.eventCaching.contentType variable=refResults.eventCaching.renderedContent;
				} else {
					WriteOutput( refResults.eventCaching.renderedContent );
				}
				// Authoritative Header
				header statuscode=203 statustext="Non-Authoritative Information";
			} else {
				// Run Default/Set Event not executing an event
				if ( not event.isNoExecution() ) {
					refResults.results = cbController.runEvent( default=true );
				}

				// No Render Test
				if ( not event.isNoRender() ) {

					// Execute preLayout Interception
					interceptorService.processState( "preLayout" );

					// Check for Marshalling and data render
					renderData = event.getRenderData();

					// Rendering/Marshalling of content
					if ( IsStruct( renderData ) and not StructisEmpty( renderData ) ) {
						renderedContent = cbController.getPlugin( "Utilities" ).marshallData( argumentCollection=renderData );

					// Check for Event Handler return results
					} elseif ( StructKeyExists( refResults, "results" ) ) {
						renderedContent = refResults.results;
					} else {
						// Render Layout/View pair via set variable to eliminate whitespace--->
						renderedContent = cbController.getPlugin( "Renderer" ).renderLayout( module=event.getCurrentLayoutModule(), viewModule=event.getCurrentViewModule() );
					}

					// PreRender Data:--->
					interceptorData.renderedContent = renderedContent;
					// Execute preRender Interception
					interceptorService.processState( "preRender", interceptorData );
					// Replace back Content From Interception
					renderedContent = interceptorData.renderedContent;

					// Check if caching the event, this is a cacheable event?
					eventCacheEntry = event.getEventCacheableEntry();
					if ( StructKeyExists( eventCacheEntry, "cacheKey"          ) and
					     StructKeyExists( eventCacheEntry, "timeout"           ) and
					     StructKeyExists( eventCacheEntry, "lastAccessTimeout" ) ) {

						lock name="#instance.appHash#.caching.#eventCacheEntry.cacheKey#" type="exclusive" timeout="10" throwontimeout="true" {
							// Double lock for concurrency
							if ( NOT templateCache.lookup( eventCacheEntry.cacheKey ) ) {

								// Prepare event caching entry
								refResults.eventCachingEntry = {
									renderedContent = renderedContent,
									renderData      = false,
									contentType     = "",
									encoding        = "",
									statusCode      = "",
									statusText      = "",
									isBinary        = false
								}

								// Render Data Caching Metadata
								if ( IsStruct( renderData ) and not structisEmpty( renderData ) ) {
									refResults.eventCachingEntry.renderData  = true;
									refResults.eventCachingEntry.contentType = renderData.contentType;
									refResults.eventCachingEntry.encoding    = renderData.encoding;
									refResults.eventCachingEntry.statusCode  = renderData.statusCode;
									refResults.eventCachingEntry.statusText  = renderData.statusText;
									refResults.eventCachingEntry.isBinary    = renderData.isBinary;
								}

								// Cache the content of the event
								templateCache.set( eventCacheEntry.cacheKey, refResults.eventCachingEntry, eventCacheEntry.timeout, eventCacheEntry.lastAccessTimeout );
							}
						}
					}

					// Render Data?
					if ( IsStruct( renderData ) and not StructisEmpty( renderData ) ) {
						event.showDebugPanel( false );
						renderDataSetup( argumentCollection=renderData );/*
						Binary
						*/if ( renderData.isBinary ) { content type=renderData.contentType variable=renderedContent;/*
						Non Binary
						*/} else { WriteOutput( renderedContent ); }
					// Normal HTML
					} else {
						WriteOutput( renderedContent );
					}

					// Execute postRender Interception
					interceptorService.processState( "postRender" );
				}

			// End else if not cached event
			}

			// If Found in config, run onRequestEnd Handler
			if ( Len( cbController.getSetting( "RequestEndHandler" ) ) ) {
				cbController.runEvent( cbController.getSetting( "RequestEndHandler" ), true );
			}

			// Execute postProcess Interception
			interceptorService.processState( "postProcess" );

			// Save Flash Scope
			if ( areSessionsEnabled() && cbController.getSetting( "flash" ).autoSave ) {
				cbController.getRequestService().getFlashScope().saveFlash();
			}
		} catch( any e ) {
			var defaultShowErrorsSetting = IsBoolean( application.injectedConfig.showErrors ?: "" ) && application.injectedConfig.showErrors;
			var showErrors               = cbController.getSetting( name="showErrors", defaultValue=defaultShowErrorsSetting );

			if ( !IsBoolean( showErrors ) || !showErrors ) {
				rethrow;
			} else {
				// Get Exception Service
				exceptionService = cbController.getExceptionService();

				// Intercept The Exception
				interceptorData = StructNew();
				interceptorData.exception = e;
				interceptorService.processState( "onException", interceptorData );

				// Handle The Exception
				ExceptionBean = exceptionService.ExceptionHandler( cfcatch, "application", "Application Execution Exception" );

				// Render The Exception
				WriteOutput( exceptionService.renderBugReport( ExceptionBean ) );
			}
		}

		// Time the request
		request.fwExecTime = getTickCount() - request.fwExecTime;

		// DebugMode Routines
		if ( cbController.getDebuggerService().getDebugMode() ) {
			// Record Profilers
			cbController.getDebuggerService().recordProfiler();
			// Render DebugPanel
			if ( event.getDebugPanelFlag() ) {
				// Render Debug Log
				WriteOutput( interceptorService.processState( "beforeDebuggerPanel" ) & cbController.getDebuggerService().renderDebugLog() & interceptorService.processState( "afterDebuggerPanel" ) );
			}
		}
	}

	/**
	 * Overrideing onSessionEnd to fix a bug
	 *
	 */
	public void function onSessionEnd( required struct sessionScope, required struct appScope ) output=false {
		var cbController = "";
		var event = "";
		var iData = structnew();

		lock type="readonly" name="#getAppHash()#" timeout="#instance.lockTimeout#" throwontimeout="true" {
			cbController = arguments.appScope[ locateAppKey() ] ?: "";
		}

		if ( not isSimpleValue(cbController) ){
			// Get Context
			event = cbController.getRequestService().getContext();

			//Execute Session End interceptors
			iData.sessionReference = arguments.sessionScope;
			iData.applicationReference = arguments.appScope;
			cbController.getInterceptorService().processState("sessionEnd",iData);

			//Execute Session End Handler
			if ( len(cbController.getSetting("SessionEndHandler")) ){
				//Place session reference on event object
				event.setValue("sessionReference", arguments.sessionScope);
				//Place app reference on event object
				event.setValue("applicationReference", arguments.appScope);
				//Execute the Handler
				cbController.runEvent(event=cbController.getSetting("SessionEndHandler"),prepostExempt=true);
			}
		}
	}


	public string function getCOLDBOX_CONFIG_FILE() output=false {
		return variables.COLDBOX_CONFIG_FILE;
	}
	public string function getCOLDBOX_APP_ROOT_PATH() output=false {
		return variables.COLDBOX_APP_ROOT_PATH;
	}
	public string function getCOLDBOX_APP_KEY() output=false {
		return variables.COLDBOX_APP_KEY;
	}
	public string function getCOLDBOX_APP_MAPPING() output=false {
		return variables.COLDBOX_APP_MAPPING;
	}

	private boolean function areSessionsEnabled() output=false {
		var appSettings = getApplicationSettings();

		return IsBoolean( appSettings.sessionManagement ?: "" ) && appSettings.sessionManagement;
	}
}