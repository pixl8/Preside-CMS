component extends="coldbox.system.Bootstrap" {

	public void function loadColdbox() {
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

	public any function getController() {
		return application[ locateAppKey() ] ?: NullValue();
	}

	function processColdBoxRequest() output="true"{
		// Get Controller Reference
		lock type="readonly" name="#variables.appHash#" timeout="#variables.lockTimeout#" throwontimeout="true"{
			var cbController = application[ locateAppKey() ];
		}
		// Local references
		var interceptorService 	= cbController.getInterceptorService();
		var cacheBox 			= cbController.getCacheBox();

		try{
			// set request time, for info purposes
			request.fwExecTime = getTickCount();
			// Load Module CF Mappings
			cbController.getModuleService().loadMappings();
			// Create Request Context & Capture Request
			var event = cbController.getRequestService().requestCapture();

			//****** PRE PROCESS *******/
			interceptorService.processState( "preProcess" );
			if( len( cbController.getSetting( "RequestStartHandler" ) ) ){
				cbController.runEvent( cbController.getSetting( "RequestStartHandler" ), true );
			}

			//****** EVENT CACHING CONTENT DELIVERY *******/
			var refResults	 = {};
			var eCacheEntry	 = event.getEventCacheableEntry();

			// Verify if event caching item is in selected cache
			if( StructKeyExists( eCacheEntry, "cachekey" ) ){
				// Get cache element.
				refResults.eventCaching = cacheBox
					.getCache( eCacheEntry.provider )
					.get( eCacheEntry.cacheKey );
			}

			// Verify if cached content existed.
			if ( !isNull( refresults.eventCaching ) ){
				// check renderdata
				if( refResults.eventCaching.renderData ){
					refResults.eventCaching.controller = cbController;
					renderDataSetup( argumentCollection=refResults.eventCaching );
				}

				// Caching Header Identifier
				getPageContextResponse().setHeader( "x-coldbox-cache-response", "true" );

				// Stop Gap for upgrades, remove by 4.2
				if( isNull( refResults.eventCaching.responseHeaders ) ){
					refResults.eventCaching.responseHeaders = {};
				}
				// Response Headers that were cached
				refResults.eventCaching.responseHeaders.each( function( key, value ){
					event.setHTTPHeader( name=key, value=value );
				} );

				// Render Content as binary or just output
				if( refResults.eventCaching.isBinary ){
					cbController.getDataMarshaller().renderContent( type="#refResults.eventCaching.contentType#", variable="#refResults.eventCaching.renderedContent#" );
				} else {
					cbController.getDataMarshaller().renderContent( type="#refResults.eventCaching.contentType#", reset=true );
					writeOutput( refResults.eventCaching.renderedContent );
				}
			} else {
				//****** EXECUTE MAIN EVENT *******/
				if( NOT event.getIsNoExecution() ){
					refResults.results = cbController.runEvent( defaultEvent=true );
				}
				//****** RENDERING PROCEDURES *******/
				if( not event.isNoRender() ){
					var renderedContent = "";

					// pre layout
					interceptorService.processState( "preLayout" );

					// Check for Marshalling and data render
					var renderData = event.getRenderData();

					// Rendering/Marshalling of content
					if( !structisEmpty( renderData ) ){
						renderedContent = cbController.getDataMarshaller().marshallData( argumentCollection=renderData );
					}
					// Check if handler returned results
					else if(
						!isNull( refResults.results )
					){
						// If simple, just return it back, evaluates to HTML
						if( isSimpleValue( refResults.results ) ){
							renderedContent = refResults.results;
						}
						// ColdBox does native JSON if you return a complex object.
						else {
							renderedContent = serializeJSON( refResults.results, true );
							getPageContextResponse().setContentType( "application/json" );
						}
					}
					// Render Layout/View pair via set variable to eliminate whitespace
					else {
						renderedContent = cbcontroller.getRenderer()
							.renderLayout( module=event.getCurrentLayoutModule(), viewModule=event.getCurrentViewModule() );
					}

					//****** PRE-RENDER EVENTS *******/
					var interceptorData = {
						  renderedContent = renderedContent
						, contentType     = renderData.contentType ?: ""
					};
					interceptorService.processState( "preRender", interceptorData );
					// replace back content in case of modification, strings passed by value
					renderedContent = interceptorData.renderedContent;

					//****** EVENT CACHING *******/
					var eCacheEntry = event.getEventCacheableEntry();
					if(
						StructKeyExists( eCacheEntry, "cacheKey" ) AND
						getPageContextResponse().getStatus() neq 500 AND
						(
							renderData.isEmpty()
							OR
							(
								StructKeyExists( renderData, "statusCode" ) and
								renderdata.statusCode neq 500
							)
						)
					){
						lock type="exclusive" name="#variables.appHash#.caching.#eCacheEntry.cacheKey#" timeout="#variables.lockTimeout#" throwontimeout="true"{

							// Try to discover the content type
							var defaultContentType = "text/html";
							// Discover from event caching first.
							if( !structisEmpty( renderData ) ){
								defaultContentType 	= renderData.contentType;
							} else {
								// Else, ask the engine
								defaultContentType = getPageContextResponse().getContentType();
							}

							// prepare storage entry
							var cacheEntry = {
								renderedContent = renderedContent,
								renderData		= false,
								contentType 	= defaultContentType,
								encoding		= "",
								statusCode		= "",
								statusText		= "",
								isBinary		= false,
								responseHeaders = event.getResponseHeaders()
							};

							// is this a render data entry? If So, append data
							if( !structisEmpty( renderData ) ){
								cacheEntry.renderData 	= true;
								structAppend( cacheEntry, renderData, true );
							}

							// Cache it
							cacheBox
								.getCache( eCacheEntry.provider )
								.set(
									eCacheEntry.cacheKey,
									cacheEntry,
									eCacheEntry.timeout,
									eCacheEntry.lastAccessTimeout
								);
						}

					} // end event caching

					// Render Data? With stupid CF whitespace stuff.
					if( !structisEmpty( renderData ) ){/*
						*/renderData.controller = cbController;renderDataSetup( argumentCollection=renderData );/*
						// Binary
						*/if( renderData.isBinary ){ cbController.getDataMarshaller().renderContent( type="#renderData.contentType#", variable="#renderedContent#" ); }/*
						// Non Binary
						*/else{ writeOutput( renderedContent ); }
					} else {
						writeOutput( renderedContent );
					}

					// Post rendering event
					interceptorService.processState( "postRender" );
				} // end no render

			} // end normal rendering procedures

			//****** POST PROCESS *******/
			if( len( cbController.getSetting( "RequestEndHandler" ) ) ){
				cbController.runEvent( event=cbController.getSetting("RequestEndHandler"), prePostExempt=true );
			}
			interceptorService.processState( "postProcess" );

			//****** FLASH AUTO-SAVE *******/
			if( areSessionsEnabled() && cbController.getSetting( "flash" ).autoSave ){
				cbController.getRequestService().getFlashScope().saveFlash();
			}

		} catch( Any e ) {
			var defaultShowErrorsSetting = IsBoolean( application.env.showErrors ?: "" ) && application.env.showErrors;
			var showErrors               = cbController.getSetting( name="showErrors", defaultValue=defaultShowErrorsSetting );

			if ( !IsBoolean( showErrors ) || !showErrors ) {
				rethrow;
			} else {
				// process the exception and render its report
				writeOutput( processException( cbController, e ) );
			}
		}

		// Time the request
		request.fwExecTime = getTickCount() - request.fwExecTime;
	}

	/**
	 * Overrideing onSessionEnd to fix a bug
	 *
	 */
	public void function onSessionEnd( required struct sessionScope, required struct appScope ) {
		var cbController = "";
		var event = "";
		var iData = structnew();

		lock type="readonly" name="#getAppHash()#" timeout="#variables.lockTimeout#" throwontimeout="true" {
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


	public string function getCOLDBOX_CONFIG_FILE() {
		return variables.COLDBOX_CONFIG_FILE;
	}
	public string function getCOLDBOX_APP_ROOT_PATH() {
		return variables.COLDBOX_APP_ROOT_PATH;
	}
	public string function getCOLDBOX_APP_KEY() {
		return variables.COLDBOX_APP_KEY;
	}
	public string function getCOLDBOX_APP_MAPPING() {
		return variables.COLDBOX_APP_MAPPING;
	}

	private boolean function areSessionsEnabled() {
		var appSettings = getApplicationSettings();

		return IsBoolean( appSettings.sessionManagement ?: "" ) && appSettings.sessionManagement;
	}
}