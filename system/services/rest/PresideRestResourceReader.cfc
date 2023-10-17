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

				apiPath = Replace( apiPath, "\", "/", "all" );

				if ( !Len( Trim( apiPath ) ) ) {
					apiPath = "/";
				}

				mappedPath = ReReplace( mappedPath, "\.cfc$", "" );
				mappedPath = ReReplace( mappedPath, "[/\\]", ".", "all" );
				mappedPath = ReReplace( mappedPath, "^\.", "" );
				mappedPath = dirCfcPathRoot & mappedPath;


				if ( isValidResource( mappedPath ) ) {
					apis[ apiPath ] = apis[ apiPath ] ?: [];

					var resourceHandlerResources = readResource( mappedPath, apiPath );
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
		return Len( preside.system.services.helpers.ComponentMetaDataReader::getComponentAttribute( arguments.cfcPath, "restUri" ) ) > 0;
	}

	/**
	 * Returns an array of REST URI mappings with CFC info
	 * for the given resource CFC (path)
	 *
	 * @cfcPath.hint Mapped component path to CFC to extract data of
	 * @api.hint     Name of the API to which the resource belongs (e.g. "/myapi/v2")
	 * @autodoc true
	 */
	public array function readResource( required string cfcPath, required string api ) {
		var verbs                     = [ "get", "post", "put", "delete", "head", "options" ];
		var validatableParameterTypes = [ "string", "date", "numeric", "uuid" ];
		var cfcFunctions              = preside.system.services.helpers.ComponentMetaDataReader::getComponentFunctions( arguments.cfcPath );
		var readMeta                  = {
			  verbs              = {}
			, requiredParameters = {}
			, parameterTypes     = {}
			, restUri            = preside.system.services.helpers.ComponentMetaDataReader::getComponentAttribute( arguments.cfcPath, "restUri" )
		};

		for( var functionName in cfcFunctions ) {
			var func = cfcFunctions[ functionName ];
			var verb = "";

			if ( ArrayFindNoCase( verbs, functionName ) ) {
				verb = functionName;
			} else if ( ArrayFindNoCase( verbs, func.restVerb ?: "" ) ) {
				verb = func.restVerb;
			}
			if ( Len( verb ) ) {
				readMeta.verbs[ verb ] = functionName;
				readMeta.requiredParameters[ verb ] = [];
				readMeta.parameterTypes[ verb ] = {};
				for ( var param in func.parameters ) {
					if ( isBoolean( param.required ?: "" ) && param.required ) {
						readMeta.requiredParameters[ verb ].append( param.name );
					}
					if ( validatableParameterTypes.findNoCase( param.type ?: "" ) ) {
						readMeta.parameterTypes[ verb ][ param.name ] = param.type;
					}
				}
			}
		}

		var resources = [];
		var uris      = ListToArray( readMeta.restUri ?: "" );
		var verbs     = [];
		var handler   = ListLast( arguments.cfcPath, "." );

		if ( arguments.api.len() && arguments.api != "/" ) {
			handler = Replace( ReReplace( arguments.api, "^/", "" ), "/", ".", "all" ) & "." & handler;
		}

		for( var uri in uris ) {
			var resource = readUri( uri );

			resource.verbs              = readMeta.verbs;
			resource.requiredParameters = readMeta.requiredParameters;
			resource.parameterTypes     = readMeta.parameterTypes;
			resource.handler            = handler;

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
			  uriPattern = "^" & ReReplace( arguments.uri, "\{.*?}", "(.*?)", "all" ) & "$"
			, tokens     = tokens
		};
	}


}
