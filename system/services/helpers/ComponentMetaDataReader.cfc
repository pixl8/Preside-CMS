/**
 * Provides wrapper logic around Lucee's objectMetaData()
 * function in order to cache the results and provider helpers
 * that automate recursive lookups along base component lines.
 *
 * @autodoc   true
 * @singleton true
 */
component {

	/**
	 * Returns a structure of found metadata of the passed component using
	 * the server scope to cache this lookup where possible
	 *
	 * @autodoc            true
	 * @componentPath.hint Path to the component to read
	 *
	 */
	public static struct function readMeta( required string componentPath ) {
		var filePath = ExpandPath( "/" & ReReplace( arguments.componentPath, "\.+", "/", "all" ) & ".cfc" );
		var cfcPath  = ReReplace( ReReplace( arguments.componentPath, "\.+", ".", "all" ), "^\.", "" );

		if ( !StructKeyExists( server, "_cfcMetaCache" ) ) {
			server._cfcMetaCache = _instantiateCache();
		}
		if ( !StructKeyExists( request, "_cfcMetaCheckedCache" ) ) {
			request._cfcMetaCheckedCache = {};
		}

		var fromCache = NullValue();
		if ( StructKeyExists( server._cfcMetaCache, cfcPath ) ) {
			try {
				fromCache = server._cfcMetaCache[ cfcPath ].get();
			} catch( any e ){}
		}

		if ( IsNull( fromCache ) || ( !StructKeyExists( request._cfcMetaCheckedCache, cfcPath ) && ( FileInfo( filePath ).dateLastModified > fromCache.lastCalculated ) ) ) {
			var cfcMeta = GetComponentMetadata( cfcPath );

			request._cfcMetaCheckedCache[ cfcPath ] = true;
			server._cfcMetaCache[ cfcPath ] = _newEntry( cfcMeta );
			fromCache = { meta=cfcMeta };
		}

		return fromCache.meta;
	}

	/**
	 * Returns a structure of recursively fetched function definitions
	 * for the given component path and its parent components.
	 *
	 * @autodoc            true
	 * @componentPath.hint Path to the component to read
	 *
	 */
	public static struct function getComponentFunctions( required string componentPath ) {
		var meta = readMeta( arguments.componentPath );
		var functions = {};

		if ( Len( meta.extends.name ?: "" ) ) {
			functions = getComponentFunctions( meta.extends.name );
		}

		if ( StructKeyExists( meta, "functions" ) && IsArray( meta.functions ) ) {
			for( var func in meta.functions ) {
				functions[ func.name ?: "" ] = func;
			}
		}

		return functions;
	}

	/**
	 * Returns the value of a given attribute on a component. This is
	 * fetched recursively so that base component definitions can provide
	 * the attribute if missing in the child.
	 *
	 * @autodoc            true
	 * @componentPath.hint Path to the component to read
	 * @attributeName.hint Name of the attribute to fetch
	 * @defaultValue.hint  Value to return if the attribute is not defined
	 *
	 */
	public static function getComponentAttribute( required string componentPath, required string attributeName, any defaultValue="" ) {
		var meta = readMeta( arguments.componentPath );

		if ( StructKeyExists( meta, arguments.attributeName ) ) {
			return meta[ arguments.attributeName ];
		}

		if ( Len( meta.extends.name ?: "" ) ) {
			return getComponentAttribute( meta.extends.name, arguments.attributeName, arguments.defaultValue );
		}

		return arguments.defaultValue;
	}

	/**
	 * Returns a struct with any of the attributes that are passed and
	 * found on the target component and any base components that it extends.
	 * If an attribute is not found, it will not be present in the returned
	 * structure.
	 *
	 * @autodoc             true
	 * @componentPath.hint  Path to the component to read
	 * @attributeNames.hint Array of attribute names to fetch
	 *
	 */
	public static struct function getComponentAttributes( required string componentPath, required array attributeNames ) {
		var meta = readMeta( arguments.componentPath );
		var attribs = {};
		var stillToFetch = [];

		for( var attribName in arguments.attributeNames ) {
			if ( StructKeyExists( meta, attribName ) ) {
				attribs[ attribName ] = meta[ attribName ];
			} else {
				ArrayAppend( stillToFetch, attribName );
			}
		}

		if ( Len( meta.extends.name ?: "" ) ) {
			StructAppend( attribs, getComponentAttributes( meta.extends.name, stillToFetch ) );
		}

		return attribs;
	}

	public static function createPersistentCache() {
		var start     = GetTickCount();
		var mappings  = [ "/preside/system", "/app", "/coldbox/system" ];
		var cacheFile = ExpandPath( "/uploads/.cache/componentMetaCache.jsonl" );

		SystemOutput( "=====================================================", true );
		SystemOutput( "Generating Persistent cache for Component metadata...", true );

		DirectoryCreate( GetDirectoryFromPath( cacheFile ), true, true );
		if ( FileExists( cachefile ) ) {
			FileDelete( cacheFile );
		}

		var openFile = FileOpen( cacheFile, "write" );

		try {
			for( var mapping in mappings ) {
				var expandedMappingPath = ExpandPath( mapping );
				var dottedMapping       = Replace( ReReplace( mapping, "^/", "" ), "/", ".", "all" );
				var cfcPaths            = DirectoryList( expandedMappingPath, true, "path", "*.cfc" );
				for( var cfcPath in cfcPaths ) {
					if ( cfcPath contains "/preside/system/externals" ) {
						continue;
					}

					var relPath       = Right( cfcPath, Len( cfcPath )-Len( expandedMappingPath ) );
					var componentPath = dottedMapping & ReReplace( Replace( relPath, "/", ".", "all" ), "\.cfc$", "" );

					try {
						var meta = readMeta( componentPath );
						FileWriteLine( openfile, SerializeJson( meta ) );
					} catch( any e ) {
						// should we??
					}
				}
			}
		} catch( any e ) {
			rethrow;
		} finally {
			FileClose( openFile );
		}

		SystemOutput( "Finished generating Persistent cache for component metadata in #LsNumberFormat( GetTickCount()-start )# ms", true );
		SystemOutput( "=====================================================", true );
	}

	private static function _instantiateCache() {
		var cache     = {};
		var cacheFile = ExpandPath( "/uploads/.cache/componentMetaCache.jsonl" );

		if ( FileExists( cacheFile ) ) {
			var openFile = FileOpen( cacheFile, "read" );

			try {
				while( !FileIsEoF( openFile ) ) {
					var ln = FileReadLine( openFile );
					if ( IsJson( ln ) ) {
						var meta = DeserializeJson( ln );
						cache[ meta.fullname ] = _newEntry( meta );
					}
				}
			} catch( any e ) {
				rethrow;
			} finally {
				FileClose( openFile );
			}
		}

		return cache;
	}

	private static function _newEntry( meta ) {
		return CreateObject( "java", "java.lang.ref.SoftReference" ).init( {
			  lastCalculated = Now()
			, meta           = arguments.meta
		} );
	}

}