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

		if ( !StructKeyExists( server, "_cfcMetaCache" ) ) {
			server._cfcMetaCache = {};
		}
		if ( !StructKeyExists( request, "_cfcMetaCache" ) ) {
			request._cfcMetaCache = {};
		}
		if ( !StructKeyExists( request._cfcMetaCache, filePath ) && ( !StructKeyExists( server._cfcMetaCache, filePath ) || FileInfo( filePath ).dateLastModified > server._cfcMetaCache[ filePath ].lastCalculated ) ) {
			request._cfcMetaCache[ filePath ] = true; // avoids double fileinfo reads to the same file in a single request
			server._cfcMetaCache[ filePath ] = {
				  lastCalculated = Now()
				, meta           = GetComponentMetadata( arguments.componentPath )
			};
		}

		return server._cfcMetaCache[ filePath ].meta;
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

}