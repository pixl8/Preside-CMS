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
	public any function init() {
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
		var urlEncodedArgsRegex = "[a-zA-Z0-9%=,_\$\s]*"
		var dvPattern       = "<!--dv:(.*?)\((#urlEncodedArgsRegex#)\)-->";
		var processed       = arguments.content;
		var cb              = $getColdbox();
		var patternFound    = false;
		var match           = "";
		var wholeMatch      = "";
		var viewlet         = "";
		var argsString      = "";
		var renderedViewlet = "";

		do {
			match        = processed.reFind( dvPattern, 1, true );
			patternFound = ( match.pos[ 1 ] ?: 0 ) > 0;

			if ( patternFound ) {
				wholeMatch  = processed.mid( match.pos[ 1 ], match.len[ 1 ] );

				viewlet     = processed.mid( match.pos[ 2 ], match.len[ 2 ] );
				argsString  = processed.mid( match.pos[ 3 ], match.len[ 3 ] );
				renderedViewlet = cb.renderViewlet(
					  event = viewlet
					, args  = _parseArgs( argsString.trim() )
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

			tag &= delim & key & "=" & UrlEncodedFormat( value );
			delim = ",";
		}

		tag &= ")-->";

		return tag;
	}

// PRIVATE HELPERS
	private struct function _parseArgs( required string args ) {
		var parsed = {};
		var keyValues = args.listToArray( "," );

		for( var keyValue in keyValues ) {
			var key   = keyValue.trim().listFirst( "=" ).trim();
			var value = keyValue.trim().listRest( "=" ).trim();

			parsed[ key ] = UrlDecode( value );

			if ( IsJson( parsed[ key ] ) ) {
				parsed[ key ] = DeserializeJSON( parsed[ key ] );
			}
		}

		return parsed;
	}

}