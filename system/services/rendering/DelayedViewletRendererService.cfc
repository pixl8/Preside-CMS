/**
 * @singleton      true
 * @presideservice true
 * @autodoc        true
 *
 * Service that deals with replacing 'delayed viewlet' markup in content with live evaluated
 * viewlet renders.
 */
component {

// CONSTRUCTOR
	/**
	 * @defaultHandlerAction.inject   coldbox:fwsetting:eventAction
	 * @contentRendererService.inject contentRendererService
	 *
	 */
	public any function init( required string defaultHandlerAction, required any contentRendererService ) {
		_setDefaultHandlerAction( arguments.defaultHandlerAction );
		_setContentRendererService( arguments.contentRendererService );
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
		var encodedArgsRegex = "[a-zA-Z0-9%=,_\$\s\+\/]*"
		var dvPattern        = "<!--dv:(.*?)\((#encodedArgsRegex#)\)\(private=(true|false),prePostExempt=(true|false)\)-->";
		var processed        = arguments.content;
		var cb               = $getColdbox();
		var patternFound     = false;
		var match            = "";
		var wholeMatch       = "";
		var viewlet          = "";
		var privateViewlet   = "";
		var prePostExempt    = "";
		var argsString       = "";
		var renderedViewlet  = "";

		do {
			match        = ReFind( dvPattern, processed, 1, true );
			patternFound = ( match.pos[ 1 ] ?: 0 ) > 0;

			if ( patternFound ) {
				wholeMatch  = Mid( processed, match.pos[ 1 ], match.len[ 1 ] );

				viewlet        = Mid( processed, match.pos[ 2 ], match.len[ 2 ] );
				argsString     = Mid( processed, match.pos[ 3 ], match.len[ 3 ] );
				privateViewlet = Mid( processed, match.pos[ 4 ], match.len[ 4 ] );
				prePostExempt  = Mid( processed, match.pos[ 5 ], match.len[ 5 ] );

				renderedViewlet = cb.renderViewlet(
					  event         = viewlet
					, args          = _parseArgs( argsString.trim() )
					, delayed       = false
					, private       = IsBoolean( privateViewlet ) && privateViewlet
					, prePostExempt = IsBoolean( prePostExempt  ) && prePostExempt
				);

				renderedViewlet = _getContentRendererService().render(
					  renderer = "richeditor"
					, data     = renderedViewlet
				);

				processed = Replace( processed, wholeMatch, renderedViewlet ?: "", "all" );
			}
		} while( patternFound )


		return processed;
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
		variables._viewletDelayedLookupCache = variables._viewletDelayedLookupCache ?: {};

		var cacheKey  = arguments.viewlet & ":default:" & arguments.defaultValue;
		var isDelayed = arguments.defaultValue;

		if ( StructKeyExists( _viewletDelayedLookupCache, cacheKey ) ) {
			return _viewletDelayedLookupCache[ cacheKey ];
		}

		if ( $isFeatureEnabled( "fullPageCaching" ) ) {
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
		} else {
			isDelayed = false;
		}

		_viewletDelayedLookupCache[ cacheKey ] = isDelayed;
		return isDelayed;
	}

// PRIVATE HELPERS
	private struct function _parseArgs( required string args ) {
		var parsed = {};
		var keyValues = args.listToArray( "," );

		for( var keyValue in keyValues ) {
			var key   = keyValue.trim().listFirst( "=" ).trim();
			var value = keyValue.trim().listRest( "=" ).trim();

			parsed[ key ] = ToString( ToBinary( value ) );

			if ( IsJson( parsed[ key ] ) ) {
				parsed[ key ] = DeserializeJSON( parsed[ key ] );
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
}