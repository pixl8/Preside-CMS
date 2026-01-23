<cffunction name="removeEmptyStructKeys" access="public" returntype="struct" output="false">
	<cfargument name="inputStruct" type="struct" required="true" /><cfsilent>

	<cfscript>
		var result = Duplicate( inputStruct );
		var key    = "";

		for( key in result ) {
			if ( IsNull( result[ key ] ) or ( IsSimpleValue( result[ key ] ) and not Len( Trim( result[ key ] ) ) ) ) {
				StructDelete( result, key );
			}
		}

		return result;
	</cfscript>
</cfsilent></cffunction>

<cffunction name="cleanStruct" access="private" returntype="void" output="false">
	<cfargument name="strct" type="struct" required="true" /><cfsilent>

	<cfscript>
		for( var key in arguments.strct ) {
			if ( IsSimpleValue( arguments.strct[ key ] ) ) {
				continue;
			}
			if ( IsStruct( arguments.strct[ key ] ) ) {
				cleanStruct( arguments.strct[ key ] );
				continue;
			}

			if ( IsArray( arguments.strct[ key ] ) ) {
				var isByteArray = isinstanceof(arguments.strct[key], "byte[]");
				if ( !isByteArray ) {
					cleanArray( arguments.strct[ key ] );
					continue;
				}
			}

			StructDelete( arguments.strct, key );
		}
	</cfscript>
</cfsilent></cffunction>

<cffunction name="cleanArray" access="private" returntype="void" output="false">
	<cfargument name="arr" type="array" required="true" /><cfsilent>
	<cfscript>
		for ( var i=ArrayLen( arguments.arr ); i>0; i-- ) {
			var item = arguments.arr[ i ];
			if ( IsSimpleValue( item ) ) {
				continue;
			}
			if ( IsStruct( item ) ) {
				cleanStruct( item );
				continue;
			}
			if ( IsArray( item ) ) {
				var isByteArray = isinstanceof(item, "byte[]");
				if ( !isByteArray ) {
					cleanArray( item );
					continue;
				}
				ArrayDeleteAt( arguments.arr, i );
			}

			ArrayDelete( arguments.arr, i );
		}
	</cfscript>
</cfsilent></cffunction>