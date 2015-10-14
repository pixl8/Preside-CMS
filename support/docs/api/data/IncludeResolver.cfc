component {

	public any function resolveIncludesInStructuredData( required any data, required string rootDirectory ) {

		if ( IsSimpleValue( arguments.data ) ) {
			return resolveIncludes( arguments.data, arguments.rootDirectory );
		}

		if ( IsArray( arguments.data ) ) {
			for( var i=1; i<=arguments.data.len(); i++ ) {
				arguments.data[ i ] = resolveIncludesInStructuredData( arguments.data[ i ], arguments.rootDirectory );
			}

			return arguments.data;
		}

		if ( IsStruct( arguments.data ) ) {
			for( var key in arguments.data ) {
				if ( !IsNull( arguments.data[ key ] ) ) {
					arguments.data[ key ] = resolveIncludesInStructuredData( arguments.data[ key ], arguments.rootDirectory );
				}
			}

			return arguments.data;
		}

		return arguments.data;
	}

	public string function resolveIncludes( required string text, required string rootDirectory ) {
		var complete = false;
		var resolved = arguments.text;

		do {
			var nextIncludeMatch = _findNextInclude( resolved );
			if ( Len( Trim( nextIncludeMatch ) ) ) {
				resolved = replace( resolved, "{{include:#nextIncludeMatch#}}", _readInclude( nextIncludeMatch, arguments.rootDirectory ) );
			} else {
				break;
			}
		} while( !complete );

		return resolved;
	}

 // PRIVATE HELPERS
	private string function _findNextInclude( required string text ) {
		var regex = "\{\{include:(.*?)\}\}";
		var result = ReFind( regex, arguments.text, 0, true );

		if ( result.pos.len() == 2 ) {
			return Mid( text, result.pos[2], result.len[2] );
		}

		return "";
	}

	private string function _readInclude( required string inc, required string rootDirectory ) {
		var fullPath = ReReplace( rootDirectory, "[\\/]$", "" ) & "/" & ReReplace( arguments.inc, "^[\\/]", "" );

		if ( FileExists( fullPath ) ) {
			return resolveIncludes( FileRead( fullPath ), fullPath );
		}

		return "{{include [#fullPath#] not found}}"
	}
 }