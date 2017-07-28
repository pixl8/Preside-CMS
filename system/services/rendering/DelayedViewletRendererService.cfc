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
	 * @defaultHandlerAction.inject coldbox:fwsetting:eventAction
	 *
	 */
	public any function init( required string defaultHandlerAction ) {
		_setDefaultHandlerAction( arguments.defaultHandlerAction );
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
		var dvPattern        = "<!--dv:(.*?)\((#encodedArgsRegex#)\)-->";
		var processed        = arguments.content;
		var cb               = $getColdbox();
		var patternFound     = false;
		var match            = "";
		var wholeMatch       = "";
		var viewlet          = "";
		var argsString       = "";
		var renderedViewlet  = "";

		do {
			match        = processed.reFind( dvPattern, 1, true );
			patternFound = ( match.pos[ 1 ] ?: 0 ) > 0;

			if ( patternFound ) {
				wholeMatch  = processed.mid( match.pos[ 1 ], match.len[ 1 ] );

				viewlet     = processed.mid( match.pos[ 2 ], match.len[ 2 ] );
				argsString  = processed.mid( match.pos[ 3 ], match.len[ 3 ] );
				renderedViewlet = cb.renderViewlet(
					  event   = viewlet
					, args    = _parseArgs( argsString.trim() )
					, delayed = false
				);

				processed = processed.replace( wholeMatch, renderedViewlet ?: "", "all" );
			}
		} while( patternFound )


		return processed;
	}

	/**
	 * Takes event name and args that would be passed to renderViewlet()
	 * and returns the special tag that can be parsed later in the request
	 *
	 * @autodoc true
	 * @event   The viewlet event name
	 * @args    Struct of args to be passed to the viewlet
	 */
	public string function renderDelayedViewletTag(
		  required string event
		, required struct args
	) {
		var tag = "<!--dv:#arguments.event#(";
		var delim = "";

		for( var key in arguments.args ) {
			var value = IsSimpleValue( arguments.args[ key ] ) ? arguments.args[ key ] :  SerializeJson( arguments.args[ key ] );

			tag &= delim & key & "=" & ToBase64( value );
			delim = ",";
		}

		tag &= ")-->";

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

		if ( _viewletDelayedLookupCache.keyExists( cacheKey ) ) {
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
		var handlerDescriptor = handlerSvc.getRegisteredHandler( event=arguments.handlerName );
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
}