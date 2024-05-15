/**
 * Service that deals with replacing 'delayed viewlet' markup in content with live evaluated
 * viewlet renders.
 *
 * @singleton      true
 * @presideservice true
 * @autodoc        true
 */
component {

// CONSTRUCTOR
	/**
	 * @defaultHandlerAction.inject         coldbox:fwsetting:eventAction
	 * @contentRendererService.inject       delayedInjector:contentRendererService
	 * @dynamicFindAndReplaceService.inject dynamicFindAndReplaceService
	 *
	 */
	public any function init( required string defaultHandlerAction, required any contentRendererService, required any dynamicFindAndReplaceService ) {
		_setDefaultHandlerAction( arguments.defaultHandlerAction );
		_setContentRendererService( arguments.contentRendererService );
		_setDynamicFindAndReplaceService( arguments.dynamicFindAndReplaceService );
		return this;
	}

// PUBLIC API METHODS
	/**
	 * Takes string content and injects dynamically rendered viewlets
	 * into locations that are marked up with delayed viewlet syntax
	 *
	 * @autodoc true
	 * @content The content to be parsed and injected with rendered viewlets
	 *
	 */
	public string function renderDelayedViewlets( required string content ) {
		if ( !$isFeatureEnabled( "delayedViewlets" ) ) {
			return arguments.content;
		}

		var encodedArgsRegex = "[a-zA-Z0-9%=,_\$\s\+\/]*"
		var dvPattern        = "<!--dv:(.*?)\((#encodedArgsRegex#)\)\(private=(true|false),prePostExempt=(true|false)\)-->";
		var cb               = $getColdbox();
		var rendererSvc      = _getContentRendererService();
		var interceptData    = {};

		interceptData.renderedContent =_getDynamicFindAndReplaceService().dynamicFindAndReplace( source=arguments.content, regexPattern=dvPattern, recurse=true, processor=function( captureGroups ){
			var renderedViewlet = cb.renderViewlet(
				  event         = ( arguments.captureGroups[ 2 ] ?: "" )
				, args          = _parseArgs( Trim( arguments.captureGroups[ 3 ] ?: "" ) )
				, delayed       = false
				, private       = IsBoolean( arguments.captureGroups[ 4 ] ?: "" ) && arguments.captureGroups[ 4 ]
				, prePostExempt = IsBoolean( arguments.captureGroups[ 5 ] ?: "" ) && arguments.captureGroups[ 5 ]
			);

			if ( !IsNull( local.renderedViewlet ) && IsSimpleValue( renderedViewlet ) ) {
				if ( $isFeatureEnabled( "cms" ) ) {
					return rendererSvc.render(
						  renderer = "richeditor"
						, data     = renderedViewlet
					);
				}
				return renderedViewlet;
			}

			return "";
		} );

		$announceInterception( "postRenderDelayedViewlets", interceptData );

		return interceptData.renderedContent ?: "";
	}

	/**
	 * Takes event name and args that would be passed to renderViewlet()
	 * and returns the special tag that can be parsed later in the request
	 *
	 * @autodoc       true
	 * @event         The viewlet event name
	 * @args          Struct of args to be passed to the viewlet
	 * @private       Whether or not the viewlet action is a private method
	 * @prePostExempt Whether or not the viewlet should skip pre/post event handlers and interception points
	 */
	public string function renderDelayedViewletTag(
		  required string  event
		, required struct  args
		,          boolean private       = true
		,          boolean prePostExempt = true
	) {
		var tag = "<!--dv:#arguments.event#(";
		var delim = "";

		for( var key in arguments.args ) {
			var value = IsSimpleValue( arguments.args[ key ] ) ? arguments.args[ key ] :  SerializeJson( arguments.args[ key ] );

			tag &= delim & key & "=" & ToBase64( ToString( value ) );
			delim = ",";
		}

		tag &= ")(private=#arguments.private#,prePostExempt=#arguments.prePostExempt#)-->";

		return tag;
	}

	/**
	 * Accepts a viewlet and returns whether or not it should be 'delayed rendered'
	 * by default
	 *
	 * @autodoc      true
	 * @viewlet      ID of the viewlet
	 * @defaultValue If the viewlet's handler does not specify any cacheable instruction, use this value
	 *
	 */
	public boolean function isViewletDelayedByDefault( required string viewlet, boolean defaultValue=false ) {
		if ( !$isFeatureEnabled( "delayedViewlets" ) ) {
			return false;
		}

		variables._viewletDelayedLookupCache = variables._viewletDelayedLookupCache ?: {};

		var cacheKey  = arguments.viewlet & ":default:" & arguments.defaultValue;
		var isDelayed = arguments.defaultValue;

		if ( StructKeyExists( _viewletDelayedLookupCache, cacheKey ) ) {
			return _viewletDelayedLookupCache[ cacheKey ];
		}

		var coldbox       = $getColdbox();
		var defaultAction = _getDefaultHandlerAction();
		var handlerName   = arguments.viewlet;
		var handlerExists = coldbox.handlerExists( handlerName );

		if ( !handlerExists ) {
			handlerName = ListAppend( handlerName, defaultAction, "." );
			handlerExists = coldbox.handlerExists( handlerName );
		}

		if ( handlerExists ) {
			var meta = _getHandlerMethodMeta( handlerName );

			if ( IsBoolean( meta.cacheable ?: "" ) ) {
				isDelayed = !meta.cacheable;
			}
		}

		_viewletDelayedLookupCache[ cacheKey ] = isDelayed;
		return isDelayed;
	}

	/**
	 * Returns whether or not the current context should allow delayed viewlets
	 *
	 * @autodoc true
	 *
	 */
	public boolean function isDelayableContext() {
		if ( !$isFeatureEnabled( "delayedViewlets" ) ) {
			return false;
		}

		var event = $getRequestContext();

		if ( event.isAdminRequest() || event.isEmailRenderingContext() || event.isBackgroundThread() || event.isApiRequest()  ) {
			return false;
		}

		return true;
	}

// PRIVATE HELPERS
	private struct function _parseArgs( required string args ) {
		var parsed       = {};
		var keyValues    = ListToArray( args, "," );
		var jsonDetector = "^[\{\[]"; // string starts with "[" or "{"

		for( var keyValue in keyValues ) {
			var key   = Trim( ListFirst( keyValue, "=" ) );
			var value = Trim( ListRest(  keyValue, "=" ) );

			parsed[ key ] = ToString( ToBinary( value ) );

			if ( ReFind( jsonDetector, parsed[ key ] ) && IsJson( parsed[ key ] ) ) {
				parsed[ key ] = DeserializeJSON( parsed[ key ], false );
			}
		}

		return parsed;
	}

	private struct function _getHandlerMethodMeta( required string handlerName ) {
		var action            = ListLast( arguments.handlerName, "." );
		var coldbox           = $getColdbox();
		var handlerSvc        = coldbox.getHandlerService();
		var handlerDescriptor = handlerSvc.getHandlerBean( event=arguments.handlerName );
		var handlerObject     = handlerSvc.getHandler( handlerDescriptor, coldbox.getRequestService().getContext() );
		var handlerMeta       = GetMetaData( handlerObject );
		var functions         = handlerMeta.functions ?: [];

		for( var func in functions ) {
			if ( ( func.name ?: "" ) == action ) {
				return func;
			}
		}

		return {};
	}

// GETTERS AND SETTERS
	private string function _getDefaultHandlerAction() {
		return _defaultHandlerAction;
	}
	private void function _setDefaultHandlerAction( required string defaultHandlerAction ) {
		_defaultHandlerAction = arguments.defaultHandlerAction;
	}

	private any function _getContentRendererService() {
		return _contentRendererService;
	}
	private void function _setContentRendererService( required any contentRendererService ) {
		_contentRendererService = arguments.contentRendererService;
	}

	private any function _getDynamicFindAndReplaceService() {
	    return _dynamicFindAndReplaceService;
	}
	private void function _setDynamicFindAndReplaceService( required any dynamicFindAndReplaceService ) {
	    _dynamicFindAndReplaceService = arguments.dynamicFindAndReplaceService;
	}
}