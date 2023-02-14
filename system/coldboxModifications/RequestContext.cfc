/**
 * Preside override of request context
 * to enable it to be a singleton
 **/
component serializable=false accessors=true extends="coldbox.system.web.context.RequestContext" {

// GETTERS and SETTERS to proxy to REQUEST scope
// enables this to be a singleton
	public struct function getContext() {
	    return request.cb_context ?: setContext( {} );
	}
	public struct function setContext( required struct context ) {
	    request.cb_context = arguments.context;
	    return request.cb_context;
	}

	public struct function getPrivateContext() {
	    return request.cb_private_context ?: setPrivateContext( {} );
	}
	public struct function setPrivateContext( required struct privateContext ) {
	    request.cb_private_context = arguments.privateContext;
	    return request.cb_private_context;
	}

	public boolean function getIsNoExecution() {
	    return request.cb_is_no_execution ?: setIsNoExecution( false );
	}
	public boolean function setIsNoExecution( required boolean isNoExecution ) {
	    request.cb_is_no_execution = arguments.isNoExecution;
	    return request.cb_is_no_execution;
	}

	public string function getSesBaseURL() {
	    return request.cb_ses_base_url ?: setSesBaseUrl( variables.defaultSESBaseURL ?: "" ).getSesBaseUrl();
	}
	function setSESBaseURL( required string sesBaseURL ){
		request.cb_ses_base_url = arguments.sesBaseURL;
		return this;
	}

	public boolean function getSesEnabled() {
		return request.cb_ses_enabled ?: setSesEnabled( false ).getSesEnabled();
	}
	function setSESEnabled( required boolean flag ){
		request.cb_ses_enabled = arguments.flag;
		return this;
	}

	public struct function getRoutedStruct() {
		return request.cb_routed_struct ?: setRoutedStruct( {} ).getRoutedStruct();
	}
	function setRoutedStruct( required struct routedStruct ){
		request.cb_routed_struct = arguments.routedStruct;
		return this;
	}

	public struct function getRenderingRegions() {
	    return request.cb_rendering_regions ?: setRenderingRegions( {} );
	}
	public struct function setRenderingRegions( required struct renderingRegions ) {
	    request.cb_rendering_regions = arguments.renderingRegions;
	    return request.cb_rendering_regions;
	}

	public boolean function isInvalidHTTPMethod(){
		return request.cb_invalid_http_method ?: false;
	}

	RequestContext function setIsInvalidHTTPMethod( boolean target=true ){
		request.cb_invalid_http_method = arguments.target;
		return this;
	}

	public struct function getResponseHeaders() {
	    return request.cb_response_headers ?: setResponseHeaders( {} );
	}

	public struct function setResponseHeaders( required struct responseHeaders ) {
	    request.cb_response_headers = arguments.responseHeaders;
	    return request.cb_response_headers;
	}

	/************************************** CONSTRUCTOR *********************************************/

	/**
	* Constructor
	*
	* @properties The ColdBox application settings
	* @controller Acess to the system controller
	*/
	function init( required struct properties={}, required any controller ){
		// Store controller;
		variables.controller 		= arguments.controller;

		// the name of the event via URL/FORM/REMOTE
		variables.eventName			= arguments.properties.eventName;

		// Registered Layouts
		variables.registeredLayouts	= structnew();
		if( structKeyExists( arguments.properties, "registeredLayouts" ) ){
			variables.registeredLayouts = arguments.properties.registeredLayouts;
		}

		// Registered Folder Layouts
		variables.folderLayouts	= structnew();
		if( structKeyExists( arguments.properties, "folderLayouts" ) ){
			variables.folderLayouts = arguments.properties.folderLayouts;
		}

		// Registered View Layouts
		variables.viewLayouts	= structnew();
		if( structKeyExists( arguments.properties, "viewLayouts" ) ){
			variables.viewLayouts = arguments.properties.viewLayouts;
		}

		// Private Modules reference
		variables.modules = arguments.properties.modules;

		// Default layout + View
		variables.defaultLayout = arguments.properties.defaultLayout;
		variables.defaultView 	= arguments.properties.defaultView;

		// SES Base URL
		variables.defaultSESBaseURL = "";
		if( structKeyExists( arguments.properties, "SESBaseURL" ) ){
			variables.defaultSESBaseURL = arguments.properties.SESBaseURL;
		}

		return this;
	}

	/************************************** COLLECTION METHODS *********************************************/


	/**
	* I Get a reference or deep copy of the public or private request Collection
	* @deepCopy Default is false, gives a reference to the collection. True, creates a deep copy of the collection.
	* @private Use public or private request collection
	*/
	struct function getCollection( boolean deepCopy=false, boolean private=false ){
		// Private Collection
		if( arguments.private ){
			if( arguments.deepCopy ){ return duplicate( getPrivateContext() ); }
			return getPrivateContext();
		}
		// Public Collection
		if ( arguments.deepCopy ){ return duplicate( getContext() ); }
		return getContext();
	}

	/**
	* Clears the entire collection
	* @private Use public or private request collection
	*/
	function clearCollection( boolean private=false ){
		if( arguments.private ) { structClear(getPrivateContext()); }
		else { structClear(getContext()); }
		return this;
	}



	/**
	* Append a structure to the collection, with overwrite or not. Overwrite = false by default
	* @collection The collection to incorporate
	* @overwrite Overwrite elements, defaults to false
	* @private Private or public, defaults public.
	*/
	function collectionAppend( required struct collection, boolean overwrite=false, boolean private=false ){
		if( arguments.private ) { structAppend(getPrivateContext(),arguments.collection, arguments.overwrite); }
		else { structAppend(getContext(),arguments.collection, arguments.overwrite); }
		return this;
	}



	/**
	* Get the collection Size
	* @private Private or public, defaults public.
	*/
	numeric function getSize( boolean private=false ){
		if( arguments.private ){ return structCount(getPrivateContext()); }
		return structCount(getContext());
	}


	/************************************** KEY METHODS *********************************************/

	/**
	* Get a value from the public or private request collection.
	* @name The key name
	* @defaultValue default value
	* @private Private or public, defaults public.
	*/
	function getValue( required name, defaultValue, boolean private=false ){
		var collection = getContext();

		// private context switch
		if( arguments.private ){ collection = getPrivateContext(); }

		// Check if key exists
		if( structKeyExists(collection, arguments.name) ){
			return collection[arguments.name];
		}

		// Default value
		if( structKeyExists(arguments, "defaultValue") ){
			return arguments.defaultValue;
		}

		throw(  message="The variable: #arguments.name# is undefined in the request collection (private=#arguments.private#)",
			detail="Keys Found: #structKeyList(collection)#",
			type="RequestContext.ValueNotFound");
	}


	/**
	* Set a value in the request collection
	* @name The key name
	* @value The value
	* @private Private or public, defaults public.
	*
	* @return RequestContext
	*/
	function setValue( required name, required value, boolean private=false ){
		var collection = getContext();
		if( arguments.private ) { collection = getPrivateContext(); }

		collection[arguments.name] = arguments.value;
		return this;
	}



	/**
	* remove a value in the request collection
	* @name The key name
	* @private Private or public, defaults public.
	*
	* @return RequestContext
	*/
	function removeValue( required name, boolean private=false ){
		var collection = getContext();
		if( arguments.private ){ collection = getPrivateContext(); }

		structDelete(collection,arguments.name);

		return this;
	}


	/**
	* Check if a value exists in the request collection
	* @name The key name
	* @private Private or public, defaults public.
	*/
	boolean function valueExists( required name, boolean private=false ){
		var collection = getContext();
		if( arguments.private ){ collection = getPrivateContext(); }
		return structKeyExists(collection, arguments.name);
	}



	/************************************** VIEW-LAYOUT METHODS *********************************************/

	/**
	* Set the view to render in this request. Private Request Collection Name: currentView, currentLayout
	* @view The name of the view to set. If a layout has been defined it will assign it, else if will assign the default layout. No extension please
	* @args An optional set of arguments that will be available when the view is rendered
	* @layout You can override the rendering layout of this setView() call if you want to. Else it defaults to implicit resolution or another override.
	* @module The explicit module view
	* @noLayout Boolean flag, wether the view sent in will be using a layout or not. Default is false. Uses a pre set layout or the default layout.
	* @cache True if you want to cache the rendered view.
	* @cacheTimeout The cache timeout in minutes
	* @cacheLastAccessTimeout The last access timeout in minutes
	* @cacheSuffix Add a cache suffix to the view cache entry. Great for multi-domain caching or i18n caching.
	* @cacheProvider The cache provider you want to use for storing the rendered view. By default we use the 'template' cache provider
	* @name This triggers a rendering region.  This will be the unique name in the request for specifying a rendering region, you can then render it by passing the unique name to renderView();
	*
	* @return RequestContext
	*/
	function setView(
		view,
		struct args={},
		layout,
		module="",
		boolean noLayout=false,
		boolean cache=false,
		cacheTimeout="",
		cacheLastAccessTimeout="",
		cacheSuffix="",
		cacheProvider="template",
		name
	){
		// Do we have an incoming rendering region definition? If we do, store it and return
		if( structKeyExists( arguments, "name" ) ){
			var renderingRegions = getRenderingRegions();
			renderingRegions[ arguments.name ] = arguments;
			return this;
		}

		// stash the view module
		getPrivateContext()[ "viewModule" ] = arguments.module;

		// Direct Layout Usage
		if( structKeyExists( arguments, "layout" ) ){
			setLayout( arguments.layout );
		}
		// Discover layout
	    else if ( NOT arguments.nolayout AND NOT getPrivateValue( name="layoutoverride", defaultValue=false ) ){

	    	//Verify that the view has a layout in the viewLayouts structure, static lookups
		    if ( structKeyExists( variables.viewLayouts, lcase( arguments.view ) ) ){
				setPrivateValue( "currentLayout", variables.viewLayouts[ lcase( arguments.view ) ] );
		    } else {
				//Check the folders structure
				for( var key in variables.folderLayouts ){
					if ( reFindnocase( '^#key#', lcase( arguments.view ) ) ){
						setPrivateValue( "currentLayout", variables.folderLayouts[ key ] );
						break;
					}
				}//end for loop
			}//end else

			// If not layout, then set default from main application
			if( not privateValueExists( "currentLayout", true ) ){
				setPrivateValue( "currentLayout", variables.defaultLayout );
			}

			// If in current module, check for a module default layout\
			var cModule	= getCurrentModule();
			if( len( cModule )
			    AND structKeyExists( variables.modules, cModule )
				AND len( variables.modules[ cModule ].layoutSettings.defaultLayout ) ){
				setPrivateValue( "currentLayout", variables.modules[ cModule ].layoutSettings.defaultLayout );
			}

		} //end layout discover

		// No Layout Rendering?
		if( arguments.nolayout ){
			removePrivateValue( 'currentLayout' );
		}

		// Do we need to cache the view
		if( arguments.cache ){
			// prepare the cache keys
			var cacheEntry = {
				view 				= arguments.view,
				timeout 			= "",
				lastAccessTimeout 	= "",
				cacheSuffix 		= arguments.cacheSuffix,
				cacheProvider 		= arguments.cacheProvider
			};

			if ( isNumeric( arguments.cacheTimeout ) ){
				cacheEntry.timeout = arguments.cacheTimeout;
			}

			if ( isNumeric( arguments.cacheLastAccessTimeout ) ){
				cacheEntry.lastAccessTimeout = arguments.cacheLastAccessTimeout;
			}

			//Save the view cache entry
			setViewCacheableEntry( cacheEntry );
		}

		// Set the current view to render.
		getPrivateContext()[ "currentView" ] = arguments.view;

		// Record the optional arguments
		setPrivateValue( "currentViewArgs", arguments.args, true );

		return this;
	}

	/**
	* Mark this request to not use a layout for rendering
	* @return RequestContext
	*/
	function noLayout(){
		// remove layout if any
		structDelete( getPrivateContext(), "currentLayout" );
		// set layout overwritten flag.
		getPrivateContext()[ "layoutoverride" ] = true;
		return this;
	}

	/**
	* Set the layout to override and render. Layouts are pre-defined in the config file. However I can override these settings if needed. Do not append a the cfm extension. Private Request Collection name
	* @name The name of the layout to set
	* @module The module to use
	*/
	function setLayout( required name, module="" ){
		// Set direct layout first.
		getPrivateContext()[ "currentLayout" ] = trim( arguments.name ) & ".cfm";
		// Do an Alias Check and override if found.
		if( structKeyExists( variables.registeredLayouts, arguments.name ) ){
			getPrivateContext()[ "currentLayout" ] = variables.registeredLayouts[ arguments.name ];
		}
		// set layout overwritten flag.
		getPrivateContext()[ "layoutoverride" ] = true;
		// module layout?
		getPrivateContext()[ "layoutmodule" ] = arguments.module;

		return this;
	}


	/**
	* Set that the request will not execute an incoming event. Most likely simulating a servlet call
	*
	* @return RequestContext
	*/
	function noExecution(){
		setIsNoExecution( true );
   		return this;
	}

	/************************************** URL METHODS *********************************************/

	/**
	 * Verify if SES is enabled or not in the request
	 */
	boolean function isSES(){
		return getSesEnabled();
	}




	/**
	* Builds links to events or URL Routes
	*
	* @to The event or route path you want to create the link to
	* @translate Translate between . to / depending on the SES mode on to and queryString arguments. Defaults to true.
	* @ssl Turn SSl on/off on URL creation, by default is SSL is enabled, we will use it.
	* @baseURL If not using SES, you can use this argument to create your own base url apart from the default of index.cfm. Example: https://mysample.com/index.cfm
	* @queryString The query string to append
	*/
	string function buildLink(
		to,
		boolean translate=true,
		boolean ssl,
		baseURL="",
		queryString=""
	){
		var frontController = "index.cfm";

		// Compatibility: Remove by 5.1
		if( !isNull( arguments.linkTo ) ){
			arguments.to = trim( arguments.linkTo );
		}

		// Check if to is defined.
		// Cleanups
		arguments.to 			= trim( arguments.to );
		arguments.baseURL 		= trim( arguments.baseURL );
		arguments.queryString 	= trim( arguments.queryString );

		// Front Controller Base
		if( len( arguments.baseURL ) neq 0 ){
			frontController = arguments.baseURL;
		}

		// SES Mode
		if( getSESEnabled() ){
			// SSL ON OR TURN IT ON
			if( isSSL() OR ( structKeyExists( arguments, "ssl" ) and arguments.ssl ) ){
				setSesBaseUrl( replacenocase( getSESBaseURL(), "http:", "https:" ) );
			}

			// SSL Turn Off
			if( structKeyExists( arguments, "ssl" ) and arguments.ssl eq false ){
				setSesBaseUrl( replacenocase( getSesBaseUrl(), "https:", "http:" ) );
			}

			// Translate link or plain
			if( arguments.translate ){
				arguments.to = replace( arguments.to, ".", "/", "all" );
				// QuqeryString Conversions
				if( len( arguments.queryString ) ){
					if( right( arguments.to, 1 ) neq  "/" ){
						arguments.to = arguments.to & "/";
					}
					arguments.to = arguments.to & replace( arguments.queryString, "&", "/", "all" );
					arguments.to = replace( arguments.to, "=", "/", "all" );
				}
			} else if( len( arguments.queryString ) ){
				arguments.to = arguments.to & "?" & arguments.queryString;
			}

			// Prepare SES Base URL Link
			var sesBaseUrl = getSesBaseUrl();
			if( right( sesBaseUrl, 1 ) eq  "/" ){
				return sesBaseUrl & arguments.to;
			} else {
				return sesBaseUrl & "/" & arguments.to;
			}
		} else {
			// Check if sending in Query String
			if( len( arguments.queryString ) eq 0 ){
				return "#frontController#?#variables.eventName#=#arguments.to#";
			} else {
				return "#frontController#?#variables.eventName#=#arguments.to#&#arguments.queryString#";
			}
		}

	}

	/************************************** CACHING *********************************************/



	/**
	 * Set an HTTP Response Header
	 *
	 * @statusCode the status code
	 * @statusText the status text
	 * @name The header name
	 * @value The header value
	 * @charset The charset to use, defaults to UTF-8
	 *
	 * @return RequestContext
	 */
	function setHTTPHeader(
		statusCode,
		statusText="",
		name,
		value=""
	){
		var responseHeaders = getResponseHeaders();

		// status code? We do not add to response headers as this is a separate marker identifier to the response
		if( structKeyExists( arguments, "statusCode" ) ){
			getPageContext().getResponse().setStatus( javaCast( "int", arguments.statusCode ), javaCast( "string", arguments.statusText ) );
		}
		// Name Exists
		else if( structKeyExists( arguments, "name" ) ){
			getPageContext().getResponse().addHeader( javaCast( "string", arguments.name ), javaCast( "string", arguments.value ) );
			responseHeaders[ arguments.name ] = arguments.value;
		} else {
			throw(
				message = "Invalid header arguments",
				detail 	= "Pass in either a statusCode or name argument",
				type 	= "RequestContext.InvalidHTTPHeaderParameters"
			);
		}

		return this;
	}

	/**
	* Returns the username and password sent via HTTP basic authentication
	*/
	struct function getHTTPBasicCredentials(){
		var results 	= {
			"username" = "",
			"password" = ""
		};

		// get credentials
		var authHeader = getHTTPHeader( "Authorization", "" );

		// continue if it exists
		if( len( authHeader ) ){
			authHeader = charsetEncode( binaryDecode( listLast( authHeader," " ), "Base64" ), "utf-8" );
			results.username = getToken( authHeader, 1, ":" );
			results.password = getToken( authHeader, 2, ":" );
		}

		return results;
    }

	/**
	* Determines if in an Ajax call or not by looking at the request headers
	*/
	boolean function isAjax(){
    	return ( getHTTPHeader( "X-Requested-With", "" ) eq "XMLHttpRequest" );
	}

	/**
	* Filters the collection or private collection down to only the provided keys.
	* @keys A list or array of keys to bring back from the collection or private collection.
	* @private Private or public, defaults public request collection
	*/
	struct function getOnly( required keys, boolean private = false ){
		if( isSimpleValue( arguments.keys ) ){
			arguments.keys = listToArray( arguments.keys );
		}
		// determine target context
		var thisContext = arguments.private ? getPrivateContext() : getContext();

		var returnStruct = {};
		for( var key in arguments.keys ){
			if( structKeyExists( thisContext, key) ){
				returnStruct[ key ] = thisContext[ key ];
			}
		}

		return returnStruct;
    }

    /**
    * Filters the private collection down to only the provided keys.
    * @keys A list or array of keys to bring back from the private collection.
    */
    struct function getPrivateOnly( required keys ){
        return getOnly( keys = keys, private = true );
    }

    /**
	* Filters the collection or private collection down to all keys except the provided keys.
	* @keys A list or array of keys to exclude from the results of the collection or private collection.
	* @private Private or public, defaults public request collection
	*/
	struct function getExcept( required keys, boolean private = false ){
		if( isSimpleValue( arguments.keys ) ){
			arguments.keys = listToArray( arguments.keys );
		}
		// determine target context
		var thisContext = arguments.private ? getPrivateContext() : getContext();

        var returnStruct = {};
		for( var key in thisContext ){
			if( ! arrayContains( arguments.keys, key ) ){
				returnStruct[ key ] = thisContext[ key ];
			}
		}

		return returnStruct;
    }



	/************************************** RESTFUL *********************************************/

	/**
	* Render data with formats
	*/
	private function renderWithFormats(){
		var viewToRender = "";

		// inflate list to array if found
		if( isSimpleValue( arguments.formats ) ){ arguments.formats = listToArray( arguments.formats ); }
		// param incoming rc.format to "html"
		paramValue( "format", "html" );
		// try to match the incoming format with the ones defined, if not defined then throw an exception
		if( arrayFindNoCase( arguments.formats, getContext().format )  ){
			// Cleanup of formats
			arguments.formats = "";
			// Determine view from incoming or implicit
			//viewToRender = ( len( arguments.formatsView ) ? arguments.formatsView : replace( reReplaceNoCase( getCurrentEvent() , "^([^:.]*):", "" ) , ".", "/" ) );
			if( len( arguments.formatsView ) ){
				viewToRender = arguments.formatsView;
			} else {
				viewToRender = replace( reReplaceNoCase( getCurrentEvent() , "^([^:.]*):", "" ) , ".", "/" );
			}
			// Rendering switch
			switch( getContext().format ){
				case "json" : case "jsonp" : case "jsont" : case "xml" : case "text" : case "wddx" : {
					arguments.type = getContext().format;
					return renderData( argumentCollection=arguments );
				}
				case "pdf" : {
					arguments.type = "pdf";
					arguments.data = variables.controller.getRenderer().renderView( view=viewToRender );
					return renderData( argumentCollection=arguments );
				}
				case "html" : case "plain" : {
					if( NOT structIsEmpty( arguments.formatsRedirect ) ){
						variables.controller.relocate( argumentCollection = arguments.formatsRedirect );
						return this;
					}
					return setView( view=viewToRender);
				}
			}
		} else {
			throw(
				message = "The incoming format #getContext().format# is not a valid registered format",
				detail 	= "Valid incoming formats are #arguments.formats.toString()#",
				type 	= "RequestContext.InvalidFormat"
			);
		}
	}

}
