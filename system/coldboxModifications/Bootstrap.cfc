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
		var templateCache		= cbController.getCacheBox().getCache( "template" );

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
			var refResults = {};
			if( structKeyExists( event.getEventCacheableEntry(), "cachekey" ) ){
				refResults.eventCaching = templateCache.get( event.getEventCacheableEntry().cacheKey );
			}
			// Verify if cached content existed.
			if ( structKeyExists( refResults, "eventCaching" ) ){
				// check renderdata
				if( refResults.eventCaching.renderData ){
					refResults.eventCaching.controller = cbController;
					renderDataSetup( argumentCollection=refResults.eventCaching );
				}

				// Authoritative Header
				getPageContext().getResponse().setStatus( 203, "Non-Authoritative Information" );
				getPageContext().getResponse().setHeader( "x-coldbox-cache-response", "true" );

				// Render Content as binary or just output
				if( refResults.eventCaching.isBinary ){
					cbController.getDataMarshaller().renderContent( type="#refResults.eventCaching.contentType#", variable="#refResults.eventCaching.renderedContent#" );
				} else {
					cbController.getDataMarshaller().renderContent( type="#refResults.eventCaching.contentType#", reset=true );
					writeOutput( refResults.eventCaching.renderedContent );
				}
			} else {
				//****** EXECUTE MAIN EVENT *******/
				if( NOT event.isNoExecution() ){
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
					if( isStruct( renderData ) and not structisEmpty( renderData ) ){
						renderedContent = cbController.getDataMarshaller().marshallData( argumentCollection=renderData );
					}
					// Check for Event Handler return results
					else if( structKeyExists( refResults, "results" ) ){
						renderedContent = refResults.results;
					}
					// Render Layout/View pair via set variable to eliminate whitespace
					else {
						renderedContent = cbcontroller.getRenderer().renderLayout( module=event.getCurrentLayoutModule(), viewModule=event.getCurrentViewModule() );
					}

					//****** PRE-RENDER EVENTS *******/
					var interceptorData = {
						renderedContent = renderedContent
					};
					interceptorService.processState( "preRender", interceptorData );
					// replace back content in case of modification
					renderedContent = interceptorData.renderedContent;

					//****** EVENT CACHING *******/
					var eCacheEntry = event.getEventCacheableEntry();
					if( structKeyExists( eCacheEntry, "cacheKey") AND
					    structKeyExists( eCacheEntry, "timeout")  AND
					    structKeyExists( eCacheEntry, "lastAccessTimeout" )
					){
						lock type="exclusive" name="#variables.appHash#.caching.#eCacheEntry.cacheKey#" timeout="#variables.lockTimeout#" throwontimeout="true"{
							// prepare storage entry
							var cacheEntry = {
								renderedContent = renderedContent,
								renderData		= false,
								contentType 	= getPageContext().getResponse().getContentType(),
								encoding		= "",
								statusCode		= "",
								statusText		= "",
								isBinary		= false
							};

							// is this a render data entry? If So, append data
							if( isStruct( renderData ) and not structisEmpty( renderData ) ){
								cacheEntry.renderData = true;
								structAppend( cacheEntry, renderData, true );
							}

							// Cache it
							templateCache.set(
								eCacheEntry.cacheKey,
								cacheEntry,
								eCacheEntry.timeout,
								eCacheEntry.lastAccessTimeout
							);
						}

					} // end event caching

					// Render Data? With stupid CF whitespace stuff.
					if( isStruct( renderData ) and not structisEmpty( renderData ) ){/*
						*/renderData.controller = cbController;renderDataSetup(argumentCollection=renderData);/*
						// Binary
						*/if( renderData.isBinary ){ cbController.getDataMarshaller().renderContent( type="#renderData.contentType#", variable="#renderedContent#" ); }/*
						// Non Binary
						*/else{ writeOutput( renderedContent ); }
					}
					else{
						writeOutput( renderedContent );
					}

					// Post rendering event
					interceptorService.processState( "postRender" );
				} // end no render

			} // end normal rendering procedures

			//****** POST PROCESS *******/
			if( len( cbController.getSetting( "RequestEndHandler" ) ) ){
				cbController.runEvent(event=cbController.getSetting("RequestEndHandler"), prePostExempt=true);
			}
			interceptorService.processState( "postProcess" );
			//****** FLASH AUTO-SAVE *******/
			if( areSessionsEnabled() && cbController.getSetting( "flash" ).autoSave ){
				cbController.getRequestService().getFlashScope().saveFlash();
			}

		}
		catch(Any e){
			var defaultShowErrorsSetting = IsBoolean( application.injectedConfig.showErrors ?: "" ) && application.injectedConfig.showErrors;
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