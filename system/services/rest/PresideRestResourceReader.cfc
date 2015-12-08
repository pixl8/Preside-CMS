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
	 * Scans passed directories for resources and returns
	 * prepared arrays of resource metadata, grouped by API, that the
	 * platform can use to route REST requests
	 *
	 * @directories.hint array of mapped directory paths
	 * @autodoc true
	 */
	public struct function readResourceDirectories( required array directories ) {
		var apis      = {};

		for( var dir in arguments.directories ) {
			var fullRootDir      = ExpandPath( dir );
			var dirCfcPathRoot   = Replace( ReReplace( ReReplace( dir, "^/", "" ), "/$", "" ), "/", ".", "all" ) & ".";
			var resourceHandlers = DirectoryList( fullRootDir, true, "path", "*.cfc" );

			for( var resourceHandler in resourceHandlers ) {
				var mappedPath = Replace( resourcehandler, fullRootDir, "" );
				var apiPath    = ListDeleteAt( mappedPath, ListLen( mappedPath, "/\" ), "/\" );

				if ( !Len( Trim( apiPath ) ) ) {
					apiPath = "/";
				}

				mappedPath = ReReplace( mappedPath, "\.cfc$", "" );
				mappedPath = ReReplace( mappedPath, "[/\\]", ".", "all" );
				mappedPath = ReReplace( mappedPath, "^\.", "" );
				mappedPath = dirCfcPathRoot & mappedPath;


				if ( isValidResource( mappedPath ) ) {
					apis[ apiPath ] = apis[ apiPath ] ?: [];

					var resourceHandlerResources = readResource( mappedPath );
					for( var newResource in resourceHandlerResources ) {
						var found = false;
						for( var existingResource in apis[ apiPath ] ) {
							if ( existingResource.uriPattern == newResource.uriPattern ) {
								existingResource.handler = newResource.handler;
								existingResource.verbs.append( newResource.verbs );

								found = true;
								break;
							}
						}

						if ( !found ) {
							apis[ apiPath ].append( newResource );
						}
					}
				}

			}
		}

		for( var api in apis ) {
			apis[ api ].sort( function( a, b ){
				var aUri = Replace( a.uriPattern, "(.*?)", "", "all" );
				var bUri = Replace( b.uriPattern, "(.*?)", "", "all" );

				return aUri.len() > bUri.len() ? -1 : 1;
			} )
		}

		return apis;
	}

	/**
	 * Returns whether or not the passed CFC path
	 * represents a valid resource CFC
	 *
	 * @cfcPath.hint Mapped component path to CFC to test the validity of
	 * @autodoc true
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
	 * @autodoc true
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
		var handler   = ListLast( arguments.cfcPath, "." );

		for( var uri in uris ) {
			var resource = readUri( uri );

			resource.verbs   = readMeta.verbs;
			resource.handler = handler;

			resources.append( resource );
		}

		return resources;
	}

	/**
	 * Parses a defined REST URI into a structure
	 * of regex pattern and named arguments
	 *
	 * @uri.hint The URI to parse
	 * @autodoc true
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