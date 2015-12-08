/**
 * Object that performs parsing of REST resource handlers.
 * The metadata gleaned from the resource can then be used
 * to map incoming requests to appropriate resource handlers.
 *
 * @autodoc true
 * @singleton
 */
component displayName="Preside REST Resource Reader" {

	/**
	 * Returns whether or not the passed CFC path
	 * represents a valid resource CFC
	 *
	 * @cfcPath.hint Mapped component path to CFC to test the validity of
	 */
	public boolean function isValidResource( required string cfcPath ) {
		var tester = function( meta ){
			if ( arguments.meta.keyExists( "restUri" ) ) {
				return true;
			}
			if ( arguments.meta.keyExists( "extends" ) ) {
				return tester( arguments.meta.extends );
			}

			return false;
		};

		return tester( GetComponentMetaData( arguments.cfcPath ) );
	}

	/**
	 * Returns an array of REST URI mappings with CFC info
	 * for the given resource CFC (path)
	 *
	 * @cfcPath.hint Mapped component path to CFC to extract data of
	 */
	public array function readResource( required string cfcPath ) {
		var readMeta = { verbs={} };
		var verbs    = [ "get", "post", "put", "delete", "head", "options" ];
		var reader = function( meta ){
			if ( arguments.meta.keyExists( "extends" ) ) {
				reader( arguments.meta.extends );
			}

			if ( arguments.meta.keyExists( "restUri" ) ) {
				readMeta.restUri = arguments.meta.restUri;
			}

			var functions = meta.functions ?: [];
			for( var func in functions ) {
				if ( verbs.findNoCase( func.name ?: "" ) ) {
					readMeta.verbs[ func.name ] = func.name;
				} else if ( verbs.findNoCase( func.restVerb ?: "" ) ) {
					readMeta.verbs[ func.restVerb ] = func.name;
				}
			}
		};

		reader( GetComponentMetaData( arguments.cfcPath ) );

		var resources = [];
		var uris      = ListToArray( readMeta.restUri ?: "" );
		var verbs     = [];

		for( var uri in uris ) {
			var resource = readUri( uri );
			resource.verbs = readMeta.verbs;
			resources.append( resource );
		}

		return resources;
	}

	/**
	 * Parses a defined REST URI into a structure
	 * of regex pattern and named arguments
	 *
	 * @uri.hint The URI to parse
	 */
	public struct function readUri( required string uri ) {
		var tokens    = [];
		var lastMatch = -1;

		do {
			lastMatch++;

			var reFindResult = ReFind( "\{(.*?)\}", arguments.uri, lastMatch, true );

			lastMatch = reFindResult.pos[ 1 ];
			if ( lastMatch ) {
				tokens.append( Mid( arguments.uri, reFindResult.pos[2], reFindResult.len[2] ) );
			}
		} while ( lastMatch );


		return {
			  uriPattern = ReReplace( arguments.uri, "\{.*?}", "(.*?)", "all" )
			, tokens     = tokens
		};
	}


}